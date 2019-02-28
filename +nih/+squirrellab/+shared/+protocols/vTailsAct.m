classdef vTailsAct < squirrellab.protocols.SquirrelLabAutoRCProtocol %squirrellab.protocols.SquirrelLabAutoRCNoiseSineProtocol
    
    properties
        amp                             % Output amplifier
        preTime = 200                   % Pulse leading duration (ms)
        preactTime = 500                % Duration of tail current
        delayPerPulse = 250       
        actTime = 1000                 % Test pulse duration (ms)
        tailTime = 1000                  % Pulse trailing duration (ms)
        
        preactSignal = -110              % activation Pulse signal value (mV or pA)
        incrementPerPulse = 10          % Increment value per each pulse (mV or pA)
        actSignal = -120          % deactivation first signal
        
        pulsesInFamily = uint16(7)     % Number of pulses in family
        numberOfAverages = uint16(3)    % Number of families
        interpulseInterval = 0          % Duration between pulses (s)
    end
    
    properties (Hidden)
        ampType
        plotData
    end
    
    methods
        
        function didSetRig(obj)
%             didSetRig@squirrellab.protocols.SquirrelLabAutoRCNoiseSineProtocol(obj);
            didSetRig@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()createPreviewStimuli(obj));
            function s = createPreviewStimuli(obj)
                s = cell(1, obj.pulsesInFamily);
                for i = 1:numel(s)
                    s{i} = obj.createAmpStimulus(i);
                end
            end
        end
        
        function prepareRun(obj)           
            prepareRun@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj);
            
            obj.showFigure('squirrellab.figures.DataFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('squirrellab.figures.AverageFigure', obj.rig.getDevice(obj.amp), ...
                    'groupBy', {'preactSignal'});
            obj.showFigure('squirrellab.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, ...
                'baselineRegion', [0 obj.preTime], ...
                'measurementRegion', [0 obj.preTime]);
            obj.showFigure('squirrellab.figures.ProgressFigure', obj.numberOfAverages * obj.pulsesInFamily);
        end
        
        function [stim, preactSignal, preactDelay] = createAmpStimulus(obj, pulseNum)
            
%             obj.preactAmp = ((0:double(obj.pulsesInFamily)-1) * obj.incrementPerPulse) + obj.preactSignal;
%             obj.preactDelay = ((0:double(obj.pulsesInFamily)-1) * obj.delayPerPulse) + obj.preactTime;
            
            preactSignal = ((double(pulseNum)-1) * obj.incrementPerPulse) + obj.preactSignal;
            preactDelay = ((double(pulseNum)-1) * obj.delayPerPulse) + obj.preactTime;
            
            maxDelay = ((double(obj.pulsesInFamily)-1) * obj.delayPerPulse) + obj.preactTime;
            
            gen1 = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen1.preTime = obj.preTime;
            gen1.stimTime = preactDelay;
            gen1.tailTime = obj.actTime + obj.tailTime + (maxDelay-preactDelay);
            gen1.mean = obj.rig.getDevice(obj.amp).background.quantity;
            gen1.amplitude = preactSignal - gen1.mean;
            gen1.sampleRate = obj.sampleRate;
            gen1.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            pulse1=gen1.generate();
            
            gen2 = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen2.preTime = obj.preTime + preactDelay;
            gen2.stimTime = obj.actTime;
            gen2.tailTime = obj.tailTime + (maxDelay-preactDelay);
            gen2.mean = 0;
            gen2.amplitude = obj.actSignal - gen1.mean;
            gen2.sampleRate = obj.sampleRate;
            gen2.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            pulse2 = gen2.generate();
            
            gen=symphonyui.builtin.stimuli.SumGenerator();
            gen.stimuli={pulse1,pulse2};
            
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj, epoch);
            if obj.runRC
                % Superclass runs RC epoch
            else %run normally
                pulseNum = mod(obj.numEpochsPrepared - 1, obj.pulsesInFamily) + 1;
                [stim, preactSignal, preactDelay] = obj.createAmpStimulus(pulseNum); %#ok<*PROPLC>
                
                epoch.addParameter('actSignal', obj.actSignal);
                epoch.addParameter('preactSignal', preactSignal);
                epoch.addParameter('preactDelay', preactDelay);
                
                epoch.addStimulus(obj.rig.getDevice(obj.amp), stim);
                epoch.addResponse(obj.rig.getDevice(obj.amp));
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
        
    end
    
end

