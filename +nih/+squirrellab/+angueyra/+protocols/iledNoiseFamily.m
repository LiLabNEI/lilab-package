classdef iledNoiseFamily < nih.squirrellab.shared.protocols.SquirrelLabProtocol
    % Presents families of gaussian noise stimuli to a specified LED.
    % Each family consists of a set of noise stimuli with the standard deviation of noise starting at startStdv. Each
    % standard deviation value is repeated repeatsPerStdv times before moving to the next standard deviation value which
    % is calculated by multiplying startStdv by stdvMultiplier^sdNum. The family is complete when this sequence has been
    % executed stdvMultiples times.
    %
    % For example, with values startStdv = 0.005, stdvMultiplier = 3, stdvMultiples = 3, and repeatsPerStdv = 5, the
    % sequence of noise stimuli standard deviation values in each family would be: 0.005 five times then 0.015 fives 
    % times then 0.045 five times.
	%
    % Also triggers 2P imaging
	% Not using electrophysiology amplififer
    % Collects frame timing and temperature
    
    properties
        led                             % Output LED
        preTime = 10000                   % Noise leading duration (ms)
        stimTime = 10000                  % Noise duration (ms)
        tailTime = 1000                  % Noise trailing duration (ms)
        frequencyCutoff = 10            % Noise frequency cutoff for smoothing (Hz)
        numberOfFilters = 4             % Number of filters in cascade for noise smoothing
        startStdv = 0.25               % First noise standard deviation, post-smoothing (V or norm. [0-1] depending on LED units)
        stdvMultiplier = 1              % Amount to multiply the starting standard deviation by with each new multiple 
        stdvMultiples = uint16(1)       % Number of standard deviation multiples in family
        repeatsPerStdv = uint16(1)      % Number of times to repeat each standard deviation multiple
        useRandomSeed = true           % Use a random seed for each standard deviation multiple?
        lightMean = 1                 % Noise and LED background mean (V or norm. [0-1] depending on LED units)
        frame                           % imaging frame monitor
    end

    properties 
        numberOfAverages = uint16(1)    % Number of families
        interpulseInterval = 0          % Duration between noise stimuli (s)
    end
    
    properties (Hidden, Dependent)
        pulsesInFamily
    end
    
    properties (Hidden)
        ledType
        frameType
    end
    
    methods
        
        function n = get.pulsesInFamily(obj)
            n = obj.stdvMultiples * obj.repeatsPerStdv;
        end
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            [obj.led, obj.ledType] = obj.createDeviceNamesProperty('LED');
            [obj.frame, obj.frameType] = obj.createDeviceNamesProperty('FrameMonitor');
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
                    s{i} = obj.createLedStimulus(i, seed);
                end
            end
        end
        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice(obj.frame));
            
            obj.rig.getDevice(obj.led).background = symphonyui.core.Measurement(obj.lightMean, 'V');
        end
        
        function [stim, stdv] = createLedStimulus(obj, pulseNum, seed)
            sdNum = floor((double(pulseNum) - 1) / double(obj.repeatsPerStdv));
            stdv = obj.stdvMultiplier^sdNum * obj.startStdv;
            
            gen = nih.squirrellab.shared.stimuli.GaussianNoiseGeneratorV2();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.stDev = stdv;
            gen.freqCutoff = obj.frequencyCutoff;
            gen.numFilters = obj.numberOfFilters;
            gen.mean = obj.lightMean;
            gen.seed = seed;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.led).background.displayUnits;
            if strcmp(gen.units, symphonyui.core.Measurement.NORMALIZED)
                gen.upperLimit = 1;
                gen.lowerLimit = 0;
            else
                gen.upperLimit = 5;
                gen.lowerLimit = -5;
            end
            
            stim = gen.generate();
        end
        
        function stim = createTriggerStimulus(obj)
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen.preTime = 0;
            gen.stimTime = 1;
            gen.tailTime = obj.preTime + obj.stimTime + obj.tailTime - 1;
            gen.amplitude = 1;
            gen.mean = 0;
            gen.sampleRate = obj.sampleRate;
            gen.units = symphonyui.core.Measurement.UNITLESS;
            
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, epoch);
            
            persistent seed;
            if ~obj.useRandomSeed
                seed = 0;
            elseif mod(obj.numEpochsPrepared - 1, obj.repeatsPerStdv) == 0
                seed = RandStream.shuffleSeed;
            end
            
            pulseNum = mod(obj.numEpochsPrepared - 1, obj.pulsesInFamily) + 1;
            [stim, stdv] = obj.createLedStimulus(pulseNum, seed);
            
            epoch.addParameter('stdv', stdv);
            epoch.addParameter('seed', seed);
            epoch.addStimulus(obj.rig.getDevice(obj.led), stim);
            
            % generate trigger
            sciscanTrigger = obj.rig.getDevices('sciscanTrigger');
            if ~isempty(sciscanTrigger)            
                epoch.addStimulus(sciscanTrigger{1}, obj.createTriggerStimulus());
            end
            
            epoch.addResponse(obj.rig.getDevice(obj.frame));
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.led);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages * obj.pulsesInFamily;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages * obj.pulsesInFamily;
        end
        
        
    end
    
end

