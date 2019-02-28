classdef vNoise <  squirrellab.protocols.SquirrelLabAutoRCProtocol %squirrellab.protocols.SquirrelLabAutoRCNoiseSineProtocol
    % Presents families of gaussian noise stimuli to a specified amplifier and records responses from a specified amplifier.
    % Each family consists of a set of noise stimuli with the standard deviation of noise starting at startStdv. Each
    % standard deviation value is repeated repeatsPerStdv times before moving to the next standard deviation value which
    % is calculated by multiplying startStdv by stdvMultiplier^sdNum. The family is complete when this sequence has been
    % executed stdvMultiples times.
    %
    % For example, with values startStdv = 0.005, stdvMultiplier = 3, stdvMultiples = 3, and repeatsPerStdv = 5, the
    % sequence of noise stimuli standard deviation values in each family would be: 0.005 five times then 0.015 five 
    % times then 0.045 five times.
    
    properties
        preTime = 100                   % Noise leading duration (ms)
        stimTime = 500                  % Noise duration (ms)
        tailTime = 100                  % Noise trailing duration (ms)
        
        startStdv = 2                   % First noise standard deviation, post-smoothing (V or norm. [0-1] depending on AMP units)
        
        frequencyCutoff = 500           % Noise frequency cutoff for smoothing (Hz)
        numberOfFilters = 4             % Number of filters in cascade for noise smoothing
        stdvMultiplier = 3              % Amount to multiply the starting standard deviation by with each new multiple 
        stdvMultiples = uint16(1)       % Number of standard deviation multiples in family
        repeatsPerStdv = uint16(5)      % Number of times to repeat each standard deviation multiple
        useRandomSeed = true            % Use a random seed for each standard deviation multiple?
        
        amp                             % Input amplifier
    end
    
    properties (Dependent, SetAccess = private)
        amp2                            % Secondary amplifier
    end
    
    properties 
        numberOfAverages = uint16(1)    % Number of families
        interpulseInterval = 0          % Duration between noise stimuli (s)
    end
    
    properties (Hidden, Dependent)
        pulsesInFamily
    end
    
    properties (Hidden)
        ampType
    end
    
    methods
        
        function n = get.pulsesInFamily(obj)
            n = obj.stdvMultiples * obj.repeatsPerStdv;
        end
        
        function didSetRig(obj)
%             didSetRig@squirrellab.protocols.SquirrelLabAutoRCNoiseSineProtocol(obj);
            didSetRig@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj, name);
            
            if strncmp(name, 'amp2', 4) && numel(obj.rig.getDeviceNames('Amp')) < 2
                d.isHidden = true;
            end
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()createPreviewStimuli(obj));
            function s = createPreviewStimuli(obj)
                s = cell(1, obj.pulsesInFamily);
                for i = 1:numel(s)
                    if ~obj.useRandomSeed
                        seed = 0;
                    elseif mod(i - 1, obj.repeatsPerStdv) == 0
                        seed = RandStream.shuffleSeed;
                    end
                    s{i} = obj.createAmpStimulus(i, seed);
                end
            end
        end
        
        function prepareRun(obj)
            prepareRun@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj);
            
            if numel(obj.rig.getDeviceNames('Amp')) < 2
                obj.showFigure('squirrellab.figures.DataFigure', obj.rig.getDevice(obj.amp));
                obj.showFigure('squirrellab.figures.ProgressFigure', obj.numberOfAverages * obj.pulsesInFamily);
                obj.showFigure('squirrellab.figures.AverageFigure', obj.rig.getDevice(obj.amp), ...
                    'prePts', obj.timeToPts(obj.preTime), ...
                    'groupBy', {'stdv'});
                obj.showFigure('squirrellab.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @std}, ...
                    'baselineRegion', [0 obj.preTime], ...
                    'measurementRegion', [obj.preTime obj.preTime+obj.stimTime]);
            else
                obj.showFigure('edu.washington.riekelab.figures.DualResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2));
                obj.showFigure('edu.washington.riekelab.figures.DualMeanResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2), ...
                    'groupBy1', {'stdv'}, ...
                    'groupBy2', {'stdv'});
                obj.showFigure('edu.washington.riekelab.figures.DualResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, obj.rig.getDevice(obj.amp2), {@mean, @var}, ...
                    'baselineRegion1', [0 obj.preTime], ...
                    'measurementRegion1', [obj.preTime obj.preTime+obj.stimTime], ...
                    'baselineRegion2', [0 obj.preTime], ...
                    'measurementRegion2', [obj.preTime obj.preTime+obj.stimTime]);
            end
            
        end
        
        function [stim, stdv] = createAmpStimulus(obj, pulseNum, seed)
            sdNum = floor((double(pulseNum) - 1) / double(obj.repeatsPerStdv));
            stdv = obj.stdvMultiplier^sdNum * obj.startStdv;
            
            gen = squirrellab.stimuli.GaussianNoiseGeneratorV2();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.stDev = stdv;
            gen.freqCutoff = obj.frequencyCutoff;
            gen.numFilters = obj.numberOfFilters;
            gen.mean = obj.rig.getDevice(obj.amp).background.quantity;
            gen.seed = seed;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj, epoch);
            
            persistent seed;
            if ~obj.useRandomSeed
                seed = 0;
            elseif mod(obj.numEpochsPrepared - 1, obj.repeatsPerStdv) == 0
                seed = RandStream.shuffleSeed;
            end
            
            pulseNum = mod(obj.numEpochsPrepared - 1, obj.pulsesInFamily) + 1;
            [stim, stdv] = obj.createAmpStimulus(pulseNum, seed);
            
            epoch.addParameter('stdv', stdv);
            epoch.addParameter('seed', seed);
            epoch.addStimulus(obj.rig.getDevice(obj.amp), stim);
            epoch.addResponse(obj.rig.getDevice(obj.amp));
            
            if numel(obj.rig.getDeviceNames('Amp')) >= 2
                epoch.addResponse(obj.rig.getDevice(obj.amp2));
            end
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages * obj.pulsesInFamily;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages * obj.pulsesInFamily;
        end
        
        function a = get.amp2(obj)
            amps = obj.rig.getDeviceNames('Amp');
            if numel(amps) < 2
                a = '(None)';
            else
                i = find(~ismember(amps, obj.amp), 1);
                a = amps{i};
            end
        end
        
    end
    
end

