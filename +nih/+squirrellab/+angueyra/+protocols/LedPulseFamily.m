classdef ledPulseFamily < squirrellab.protocols.SquirrelLabProtocol
    
    properties
        led                             % Output LED
        preTime = 100                   % Pulse leading duration (ms)
        stimTime = 10                   % Pulse duration (ms)
        tailTime = 390                  % Pulse trailing duration (ms)
        firstLightAmplitude = 3         % First pulse amplitude (V)
        incrementPerPulse = 0.5         % Cumulative amplitude increase per trial (V)
        pulsesInFamily = uint16(12)     % Number of pulses in family
        lightMean = 0                   % Pulse and LED background mean (V)
        amp                             % Input amplifier
        numberOfAverages = uint16(5)    % Number of families
        interpulseInterval = 0          % Duration between pulses (s)
    end
    
    properties (Hidden)
        ledType
        ampType
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@squirrellab.protocols.SquirrelLabProtocol(obj);
            
            [obj.led, obj.ledType] = obj.createDeviceNamesProperty('LED');
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()createPreviewStimuli(obj));
            function s = createPreviewStimuli(obj)
                s = cell(1, obj.pulsesInFamily);
                for i = 1:numel(s)
                    s{i} = obj.createLedStimulus(i);
                end
            end
        end
        
        function prepareRun(obj)
            prepareRun@squirrellab.protocols.SquirrelLabProtocol(obj);
            
            obj.showFigure('squirrellab.figures.DataFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('squirrellab.figures.AverageFigure', obj.rig.getDevice(obj.amp), ...
                'prepts',obj.timeToPts(obj.preTime),...
                'groupBy', {'lightAmplitude'});
            obj.showFigure('squirrellab.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, ...
                'baselineRegion', [0 obj.preTime], ...
                'measurementRegion', [obj.preTime obj.preTime+obj.stimTime]);
            
            obj.rig.getDevice(obj.led).background = symphonyui.core.Measurement(obj.lightMean, 'V');
        end
        
        function [stim, lightAmplitude] = createLedStimulus(obj, pulseNum)
            lightAmplitude = obj.incrementPerPulse *(double(pulseNum) - 1) + obj.firstLightAmplitude;
            
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.amplitude = lightAmplitude;
            gen.mean = obj.lightMean;
            gen.sampleRate = obj.sampleRate;
            gen.units = 'V';
            
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@squirrellab.protocols.SquirrelLabProtocol(obj, epoch);
            
            pulseNum = mod(obj.numEpochsPrepared - 1, obj.pulsesInFamily) + 1;
            [stim, lightAmplitude] = obj.createLedStimulus(pulseNum);
            
            epoch.addParameter('lightAmplitude', lightAmplitude);
            epoch.addStimulus(obj.rig.getDevice(obj.led), stim);
            epoch.addResponse(obj.rig.getDevice(obj.amp));
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@squirrellab.protocols.SquirrelLabProtocol(obj, interval);
            
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

