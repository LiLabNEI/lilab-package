classdef LedAndSciscanTrigger  < symphonyui.core.Protocol
    % Test protocol to send trigger to sciscan over the digital output
    % Modified from example LedPulse protocol & trigger code adapted from
    % Juan's iLEDPulse protocol.
    %
    % -xoxo JB, 9-27-2018
    
    
    properties
        trigger                         % Trigger to use to tell SciScan to start scanning
        amp                             % Input amplifier
        led                             % LED device

        triggerDelay = 250                  % Time until trigger is sent (ms)
        triggerDuration = 5             % Time for the trigger to latch high (ms) (shorter the better as long as it works)
        
        ledDelay = 50                  % Time until trigger is sent (ms)
        ledDuration = 150             % Time for the trigger to latch high (ms) (shorter the better as long as it works)
        
        lightAmplitude = 5              % Pulse amplitude (V)
        lightMean = 0                   % Pulse and LED background mean (V)
        
        totalTime = 2500                % Protocol duration (ms)
        numberOfAverages = uint16(1)    % Number of epochs
        interpulseInterval = 0          % Duration between pulses (s)
    end
    
    properties (Hidden)
        ledType
        triggerType  %Not sure I need this?
        ampType
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@symphonyui.core.Protocol(obj);
            
            [obj.led, obj.ledType] = obj.createDeviceNamesProperty('LED');
            [obj.trigger, obj.triggerType] = obj.createDeviceNamesProperty('trigger'); %Lowercase because that's what I used when naming the sciscan trigger in the rig description
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()obj.createStimPreviews());
        end
        
        function prepareRun(obj)
            prepareRun@symphonyui.core.Protocol(obj);
            
            obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('symphonyui.builtin.figures.MeanResponseFigure', obj.rig.getDevice(obj.amp));
            
            
            %Also need to figure out what the hell
            %"responsestatisticsfigure" is actually doing with the
            %arguments I send it. Black box right now afaik
            obj.showFigure('symphonyui.builtin.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, ...
                'baselineRegion', [0 obj.triggerDelay], ...
                'measurementRegion', [obj.triggerDelay obj.totalTime]);
            
        end

        
        
        function stims = createStimPreviews(obj)
            stims{1} = obj.createLedStimulus();
            stims{2} = obj.createTriggerStimulus();
        end
            
        
        
        function stim = createLedStimulus(obj)
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen.preTime = obj.ledDelay;
            gen.stimTime = obj.ledDuration;
            gen.tailTime = obj.totalTime - (obj.ledDelay + obj.ledDuration);
            gen.amplitude = obj.lightAmplitude;
            gen.mean = obj.lightMean;
            gen.sampleRate = obj.sampleRate;
            gen.units = 'V';
            
            stim = gen.generate();
        end
        
        
        
        function stim = createTriggerStimulus(obj)
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen.preTime = obj.triggerDelay;
            gen.stimTime = obj.triggerDuration;
            gen.tailTime = obj.totalTime - (obj.triggerDelay + obj.triggerDuration);
            
            gen.amplitude = 1;
            gen.mean = 0;
            gen.sampleRate = obj.sampleRate;
            gen.units = symphonyui.core.Measurement.UNITLESS;
            
            stim = gen.generate();
        end

        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@symphonyui.core.Protocol(obj, epoch);
            
            epoch.addStimulus(obj.rig.getDevice(obj.trigger), obj.createTriggerStimulus());
            epoch.addStimulus(obj.rig.getDevice(obj.led), obj.createLedStimulus());
            epoch.addResponse(obj.rig.getDevice(obj.amp));  %Again, how does addResponse know what stream to use on the amplifier as the response?
        end
        
        
        
        %Not sure yet what this prepareInterval function is supposed to do
        function prepareInterval(obj, interval)
            prepareInterval@symphonyui.core.Protocol(obj, interval);
            
            device = obj.rig.getDevice(obj.led);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
    end
    
end

