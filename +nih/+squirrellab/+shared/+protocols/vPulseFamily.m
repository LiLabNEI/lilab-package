classdef vPulseFamily < nih.squirrellab.shared.protocols.SquirrelLabAutoRCProtocol 
    % Presents families of rectangular pulse stimuli to a specified amplifier and records responses from the same
    % amplifier. Each family consists of a set of pulse stimuli with signal value starting at firstPulseSignal. With
    % each subsequent pulse in the family, the signal value is incremented by incrementPerPulse. The family is complete
    % when this sequence has been executed pulsesInFamily times.
    %
    % For example, with values firstPulseSignal = 100, incrementPerPulse = 10, and pulsesInFamily = 5, the sequence of
    % pulse stimuli signal values would be: 100 then 110 then 120 then 130 then 140.
		
    properties
        amp                             % Output amplifier
        preTime = 100                   % Pulse leading duration (ms)
        stimTime = 500                  % Pulse duration (ms)
        tailTime = 1500                 % Pulse trailing duration (ms)
        firstPulseSignal = -60          % First pulse signal value (mV or pA)
        incrementPerPulse = 10          % Increment value per each pulse (mV or pA)
        leakSub = true                  % Attempt leak subtraction with 5mV pulses
        leakN = uint16(2)               % Number of pairs of low voltage stimuli to run for leak subtraction
        pulsesInFamily = uint16(15)     % Number of pulses in family
    end
    
    properties (Dependent, SetAccess = private)
        amp2                            % Secondary amplifier
    end
	
    properties
        amp2PulseSignal = -60           % Pulse signal value for secondary amp (mV or pA depending on amp2 mode)
        numberOfAverages = uint16(1)    % Number of families
        interpulseInterval = 0          % Duration between pulses (s)
    end
	
    properties (Hidden)
        ampType
        nPulses
        plotData
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.SquirrelLabAutoRCProtocol(obj);

            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, name);
        
            if strncmp(name, 'amp2', 4) && numel(obj.rig.getDeviceNames('Amp')) < 2
                d.isHidden = true;
            end
        end
		
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()createPreviewStimuli(obj));
            function s = createPreviewStimuli(obj)
                [nPulses, ~] = obj.leakParsing; %#ok<*PROPLC>
                s = cell(1, nPulses);
                for i = 1:numel(s)
                    s{i} = obj.createAmpStimulus(i);
                end
            end
        end
        
        function prepareRun(obj)           
            prepareRun@nih.squirrellab.shared.protocols.SquirrelLabAutoRCProtocol(obj);
            
            [obj.nPulses, pulseAmp] = obj.leakParsing;
            if numel(obj.rig.getDeviceNames('Amp')) < 2
	            % Data Figure
	            obj.showFigure('nih.squirrellab.shared.figures.DataFigure', obj.rig.getDevice(obj.amp));
	            % Mean Figure + IV
	            obj.showFigure('nih.squirrellab.shared.figures.vPulseFamilyIVFigure', obj.rig.getDevice(obj.amp), ...
	                'prepts',obj.timeToPts(obj.preTime),...
	                'stmpts',obj.timeToPts(obj.stimTime),...
	                'nPulses',double(obj.nPulses),...
	                'pulseAmp',pulseAmp+obj.rig.getDevice(obj.amp).background.quantity,...
	                'groupBy', {'pulseSignal'});
	            %Baseline and StD tracking
	            obj.showFigure('nih.squirrellab.shared.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @std}, ...
	                'baselineRegion', [0 obj.preTime], ...
	                'measurementRegion', [obj.preTime obj.preTime+obj.stimTime]);
	            obj.showFigure('nih.squirrellab.shared.figures.ProgressFigure', obj.numberOfAverages * obj.nPulses);
            else
                obj.showFigure('nih.squirrellab.shared.figures.DualResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2));
                obj.showFigure('nih.squirrellab.shared.figures.DualMeanResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2), ...
                    'groupBy1', {'pulseSignal'}, ...
                    'groupBy2', {'pulseSignal'});
                obj.showFigure('nih.squirrellab.shared.figures.DualResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, obj.rig.getDevice(obj.amp2), {@mean, @var}, ...
                    'baselineRegion1', [0 obj.preTime], ...
                    'measurementRegion1', [obj.preTime obj.preTime+obj.stimTime], ...
                    'baselineRegion2', [0 obj.preTime], ...
                    'measurementRegion2', [obj.preTime obj.preTime+obj.stimTime]);
            end
        end
        
        function [stim, pulseSignal] = createAmpStimulus(obj, pulseNum)
            
            [~, pulseAmp] = obj.leakParsing;
            pulseSignal = pulseAmp(pulseNum);
            
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.mean = obj.rig.getDevice(obj.amp).background.quantity;
            gen.amplitude = pulseSignal;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            stim = gen.generate();
        end
		
        function stim = createAmp2Stimulus(obj)
            gen = symphonyui.builtin.stimuli.PulseGenerator();
        
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.mean = obj.rig.getDevice(obj.amp2).background.quantity;
            gen.amplitude = obj.amp2PulseSignal - gen.mean;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.amp2).background.displayUnits;
        
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.SquirrelLabAutoRCProtocol(obj, epoch);
            if obj.runRC
                % Superclass runs RC epoch
            else %run normally
                [nPulses, ~] = obj.leakParsing;
                
                pulseNum = mod(obj.numEpochsPrepared - 1, nPulses) + 1;
                [stim, pulseSignal] = obj.createAmpStimulus(pulseNum);
                
                epoch.addParameter('pulseSignal', pulseSignal+obj.rig.getDevice(obj.amp).background.quantity);
                epoch.addStimulus(obj.rig.getDevice(obj.amp), stim);
                epoch.addResponse(obj.rig.getDevice(obj.amp));

	            if numel(obj.rig.getDeviceNames('Amp')) >= 2
	                epoch.addStimulus(obj.rig.getDevice(obj.amp2), obj.createAmp2Stimulus());
	                epoch.addResponse(obj.rig.getDevice(obj.amp2));
	            end
            end
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@nih.squirrellab.shared.protocols.SquirrelLabAutoRCProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages * obj.nPulses;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages * obj.nPulses;
        end
        
        function [nPulses, pulseAmp] = leakParsing(obj)    
            if obj.leakSub
                leakPulses = repmat([-5 5],1,obj.leakN);
                nLeakPulses = size(leakPulses,2);
            else
                leakPulses = [];
                nLeakPulses = 0;
            end
            nPulses = obj.pulsesInFamily + nLeakPulses;
            pulseAmp = [leakPulses ((0:double(obj.pulsesInFamily)-1) * obj.incrementPerPulse) + obj.firstPulseSignal]; 
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

