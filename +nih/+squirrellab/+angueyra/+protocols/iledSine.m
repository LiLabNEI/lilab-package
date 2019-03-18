classdef iledSine < nih.squirrellab.shared.protocols.SquirrelLabProtocol
    % LED sine that also triigers 2P imaging
	% LED is turned off after the set of epochs is completed.
	% Not using electrophysiology amplififer
    % Collects frame timing and temperature
    properties
	    led                             % Output LED
	    preTime = 100                   % Pulse leading duration (ms)
	    stimTime = 1000                 % Pulse duration (ms)
	    tailTime = 100                  % Pulse trailing duration (ms)
	    lightMean = 5                   % Pulse and LED background mean (V)
	    lightAmplitude = 2              % Pulse amplitude (V)
	    phaseShift = 0                  % Phase
	    sineFreq = 5                  	% Frequency (Hz)
        frame                           % imaging frame monitor
    end
    
	properties
	    numberOfAverages = uint16(1)    % Number of epochs
	    interpulseInterval = 0          % Duration between pulses (s)
	end
	
    properties (Hidden)
        ledType
        frameType
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            [obj.led, obj.ledType] = obj.createDeviceNamesProperty('LED');
            [obj.frame, obj.frameType] = obj.createDeviceNamesProperty('FrameMonitor');
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()obj.createLedStimulus());
        end
        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice(obj.frame));
            
            obj.rig.getDevice(obj.led).background = symphonyui.core.Measurement(obj.lightMean, 'V');
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
            
            % generate trigger
            sciscanTrigger = obj.rig.getDevices('sciscanTrigger');
            if ~isempty(sciscanTrigger)            
                epoch.addStimulus(sciscanTrigger{1}, obj.createTriggerStimulus());
            end
            
            epoch.addStimulus(obj.rig.getDevice(obj.led), obj.createLedStimulus());
            epoch.addResponse(obj.rig.getDevice(obj.frame));
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
    end
    
end

