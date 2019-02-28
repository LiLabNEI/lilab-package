classdef ledSine < squirrellab.protocols.SquirrelLabProtocol
    
    properties
        led                             % Output LED
        preTime = 100                    % Pulse leading duration (ms)
        stimTime = 1000                  % Pulse duration (ms)
        tailTime = 100                  % Pulse trailing duration (ms)
        lightMean = 5                   % Pulse and LED background mean (V)
        lightAmplitude = 2              % Pulse amplitude (V)
        phaseShift = 0                  % Phase
        sineFreq = 5                  % Phase
        amp                             % Input amplifier
        frame                           % Frame monitor
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
            didSetRig@squirrellab.protocols.SquirrelLabProtocol(obj);
            
            [obj.led, obj.ledType] = obj.createDeviceNamesProperty('LED');
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
            [obj.frame, obj.frameType] = obj.createDeviceNamesProperty('FrameMonitor');
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()obj.createLedStimulus());
        end
        
        function prepareRun(obj)
            prepareRun@squirrellab.protocols.SquirrelLabProtocol(obj);
            
            obj.showFigure('squirrellab.figures.DataFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('squirrellab.figures.AverageFigure', obj.rig.getDevice(obj.amp),'prepts',obj.timeToPts(obj.preTime));
            obj.showFigure('squirrellab.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, ...
                'baselineRegion', [0 obj.preTime], ...
                'measurementRegion', [obj.preTime obj.preTime+obj.stimTime]);
            
            obj.rig.getDevice(obj.led).background = symphonyui.core.Measurement(obj.lightMean, 'V');
        end
        
        function stim = createLedStimulus(obj)
            gen = symphonyui.builtin.stimuli.SineGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.period = 1000/obj.sineFreq;
            gen.phase = obj.phaseShift;
            gen.mean = obj.lightMean;
            gen.amplitude = obj.lightAmplitude;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.led).background.displayUnits;
            
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@squirrellab.protocols.SquirrelLabProtocol(obj, epoch);
            
            epoch.addStimulus(obj.rig.getDevice(obj.led), obj.createLedStimulus());
            epoch.addResponse(obj.rig.getDevice(obj.amp));
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@squirrellab.protocols.SquirrelLabProtocol(obj, interval);
            
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
            completeRun@squirrellab.protocols.SquirrelLabProtocol(obj);
            
            disp('completed')
            %turn off LED after running all epochs
            device=obj.rig.getDevice(obj.led);
            device.background = symphonyui.core.Measurement(0, 'V');
            device.applyBackground();
        end
        
    end
    
end

