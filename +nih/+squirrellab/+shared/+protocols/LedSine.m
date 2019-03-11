classdef LedSine < nih.squirrellab.shared.protocols.SquirrelLabProtocol
    % Presents a set of sinusoindal stimuli to a specified LED and records from a specified amplifier.
	% LED is turned off after the set of epochs is completed.
	
    properties
        led                             % Output LED
        preTime = 100                    % Pulse leading duration (ms)
        stimTime = 1000                  % Pulse duration (ms)
        tailTime = 100                  % Pulse trailing duration (ms)
        lightMean = 5                   % Pulse and LED background mean (V)
        lightAmplitude = 2              % Pulse amplitude (V)
        phaseShift = 0                  % Phase
        sineFreq = 5                  % Phase
		amp
	end
	
    properties (Dependent, SetAccess = private)
        amp2                            % Secondary amplifier
        frame                           % Frame monitor %JUAN: Will this make frame monitor optional? Need to make a "getPropertyDescriptor"?
    end
    
	properties
	    numberOfAverages = uint16(1)    % Number of epochs
	    interpulseInterval = 0          % Duration between pulses (s)
	end
    
    properties (Hidden)
        ledType
        ampType
        frameType
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            [obj.led, obj.ledType] = obj.createDeviceNamesProperty('LED');
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
            [obj.frame, obj.frameType] = obj.createDeviceNamesProperty('FrameMonitor');
        end
		
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, name);
            
            if strncmp(name, 'amp2', 4) && numel(obj.rig.getDeviceNames('Amp')) < 2
                d.isHidden = true;
            end
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()obj.createLedStimulus());
        end
        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            if numel(obj.rig.getDeviceNames('Amp')) < 2
	            obj.showFigure('nih.squirrellab.shared.figures.DataFigure', obj.rig.getDevice(obj.amp));
	            obj.showFigure('nih.squirrellab.shared.figures.AverageFigure', obj.rig.getDevice(obj.amp),'prepts',obj.timeToPts(obj.preTime));
	            obj.showFigure('nih.squirrellab.shared.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, ...
	                'baselineRegion', [0 obj.preTime], ...
	                'measurementRegion', [obj.preTime obj.preTime+obj.stimTime]);
            else
                obj.showFigure('edu.washington.riekelab.figures.DualResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2));
                obj.showFigure('edu.washington.riekelab.figures.DualMeanResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2));
                obj.showFigure('edu.washington.riekelab.figures.DualResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, obj.rig.getDevice(obj.amp2), {@mean, @var}, ...
                    'baselineRegion1', [0 obj.preTime], ...
                    'measurementRegion1', [obj.preTime obj.preTime+obj.stimTime], ...
                    'baselineRegion2', [0 obj.preTime], ...
                    'measurementRegion2', [obj.preTime obj.preTime+obj.stimTime]);
            end
            device = obj.rig.getDevice(obj.led);
            device.background = symphonyui.core.Measurement(obj.lightMean, device.background.displayUnits);
        end
        
        function stim = createLedStimulus(obj)
            gen = symphonyui.builtin.stimuli.SineGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.period = 1000/obj.sineFreq; % converting to ms
            gen.phase = obj.phaseShift;
            gen.mean = obj.lightMean;
            gen.amplitude = obj.lightAmplitude;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.led).background.displayUnits;
            
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, epoch);
            
            epoch.addStimulus(obj.rig.getDevice(obj.led), obj.createLedStimulus());
            epoch.addResponse(obj.rig.getDevice(obj.amp));

            if numel(obj.rig.getDeviceNames('Amp')) >= 2
                epoch.addResponse(obj.rig.getDevice(obj.amp2));
            end
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.led);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
        function completeRun(obj)
            completeRun@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            %turn off LED after running all epochs
            device=obj.rig.getDevice(obj.led);
            device.background = symphonyui.core.Measurement(0, 'V');
            device.applyBackground();
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

