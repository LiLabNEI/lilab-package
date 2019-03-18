classdef iledPulse_2leds < nih.squirrellab.shared.protocols.SquirrelLabProtocol
    % LED pulse that also triigers 2P imaging
	% Not using electrophysiology amplififer
    % Collects frame timing and temperature
    properties
        preTime = 100                    % Pulse leading duration (ms)
        stimTime = 1000                  % Pulse duration (ms)
        tailTime = 1000                  % Pulse trailing duration (ms)
        frame                           % imaging frame monitor
    end
	
    properties
        led1 = 'mx405led'                             % Output LED
        led1Amplitude = .5               % Pulse amplitude (V)
        led1Mean = 0                   % Pulse and LED background mean (V)
    end

	
    properties
		led2 = 'mx590led'                             % Output LED
		led2Amplitude = .5               % Pulse amplitude (V)
		led2Mean = 0                   % Pulse and LED background mean (V)
	end

    properties
	    numberOfAverages = uint16(1)    % Number of epochs
	    interpulseInterval = 0          % Duration between pulses (s)
	end
    
    properties (Hidden)
        led1Type
		led2Type
        frameType
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            [obj.led1, obj.led1Type] = obj.createDeviceNamesProperty('LED');
			[obj.led2, obj.led2Type] = obj.createDeviceNamesProperty('LED');
            [obj.frame, obj.frameType] = obj.createDeviceNamesProperty('FrameMonitor');
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()obj.createLedStimulus(1));
        end
        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice(obj.frame));
            
            obj.rig.getDevice(obj.led1).background = symphonyui.core.Measurement(obj.led1Mean, 'V');
			obj.rig.getDevice(obj.led2).background = symphonyui.core.Measurement(obj.led2Mean, 'V');
        end
        
        function stim = createLedStimulus(obj,epochNum)
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.amplitude = obj.determineAmplitude(epochNum);
            gen.mean = obj.determineMean(epochNum);
            gen.sampleRate = obj.sampleRate;
            gen.units = 'V';
            
            stim = gen.generate();
        end
		
        function amplitude = determineAmplitude(obj, epochNum)
           idx = mod(epochNum - 1, 2) + 1;
           if idx == 1
               amplitude = obj.led1Amplitude;
           elseif idx == 2
               amplitude  = obj.led2Amplitude;
           end
        end
		
        function ledMean = determineMean(obj, epochNum)
           idx = mod(epochNum - 1, 2) + 1;
           if idx == 1
               ledMean = obj.led1Mean;
           elseif idx == 2
               ledMean  = obj.led2Mean;
           end
        end
		
        function device = determineDevice(obj, epochNum)
            idx = mod(epochNum - 1, 2) + 1;
            if idx == 1
                device = obj.rig.getDevice(obj.led1);
            elseif idx == 2
                device = obj.rig.getDevice(obj.led2);
            end
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
			
            % get epoch number
            epochNum = obj.numEpochsPrepared;
            epoch.addStimulus(obj.determineDevice(epochNum), obj.createLedStimulus(epochNum));
            epoch.addResponse(obj.rig.getDevice(obj.frame));
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, interval);
            
            device1 = obj.rig.getDevice(obj.led1);
            interval.addDirectCurrentStimulus(device1, device1.background, obj.interpulseInterval, obj.sampleRate);
			
            device2 = obj.rig.getDevice(obj.led2);
            interval.addDirectCurrentStimulus(device2, device2.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
    end
    
end

