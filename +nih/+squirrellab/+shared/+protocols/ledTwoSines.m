classdef ledTwoSines < squirrellab.protocols.SquirrelLabProtocol
    % First epoch: led1 only; Second epoch = led2 only; Third epoch: led1 +
    % led2
    
    properties
        preTime = 200
        stimTime = 1000
        tailTime = 200
        sineFrequency = 2        % in Hz
        led1
        Amp1 = 1
        lightMean1 = 4
        led2
        Amp2 = 1
        lightMean2 = 4
        phaseShift = 180 % in degrees
        amp
        ampHoldSignal = -60
        numberOfAverages = uint16(6)    % Number of epochs
        interpulseInterval = 0          % Duration between pulses (s)
    end
    
    properties (Hidden)
        led1Type
        led2Type
        ampType
        period
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@squirrellab.protocols.SquirrelLabProtocol(obj);
            
            [obj.led1, obj.led1Type] = obj.createDeviceNamesProperty('LED');
            [obj.led2, obj.led2Type] = obj.createDeviceNamesProperty('LED');
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
            obj.period = 1000 / (obj.sineFrequency);
        end
        
            
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()createPreviewStimuli(obj));
            function s = createPreviewStimuli(obj)
                numPulses = 1;
                s = cell(numPulses*2, 1);
                for i = 1:numPulses
                    [s{2*i-1}, s{2*i}] = obj.createLedStimulus(i);
                end
            end
        end
        
        function prepareRun(obj)
            prepareRun@squirrellab.protocols.SquirrelLabProtocol(obj);
            

            obj.showFigure('squirrellab.figures.DataFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('squirrellab.figures.AverageFigure', obj.rig.getDevice(obj.amp), 'prepts',obj.timeToPts(obj.preTime),...
                'GroupBy',{'PlotGroup'});
            obj.showFigure('squirrellab.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, ...
                'baselineRegion', [0 obj.preTime], ...
                'measurementRegion', [obj.preTime obj.preTime+obj.stimTime]);

            device1 = obj.rig.getDevice(obj.led1);
            device1.background = symphonyui.core.Measurement(obj.lightMean1, device1.background.displayUnits);
            device2 = obj.rig.getDevice(obj.led2);
            device2.background = symphonyui.core.Measurement(obj.lightMean2, device2.background.displayUnits);
        end
        
        function [stim1, stim2] = createLedStimulus(obj, pulseNum)
            gen = symphonyui.builtin.stimuli.SineGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.period = obj.period;
            gen.phase = 0;
            gen.mean = obj.lightMean1;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.led1).background.displayUnits;

            gen.amplitude = obj.Amp1;
            if (rem(pulseNum, 3) == 2)
                gen.amplitude = 0;
            end
            
            stim1 = gen.generate();

            gen.mean = obj.lightMean2;
            gen.phase = obj.phaseShift;
            gen.amplitude = obj.Amp2;
            if (rem(pulseNum, 3) == 1)
                gen.amplitude = 0;
            end
   
            stim2 = gen.generate();
     
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@squirrellab.protocols.SquirrelLabProtocol(obj, epoch);
             % Add LED stimulus.
            [stim1, stim2] = obj.createLedStimulus(obj.numEpochsPrepared);
            cnt = rem(obj.numEpochsPrepared, 3);
            epoch.addParameter('PlotGroup', cnt);
            
            epoch.addStimulus(obj.rig.getDevice(obj.led1), stim1);
            epoch.addStimulus(obj.rig.getDevice(obj.led2), stim2);
            epoch.addResponse(obj.rig.getDevice(obj.amp));
            
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@squirrellab.protocols.SquirrelLabProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.led1);
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