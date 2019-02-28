classdef vHCF <  squirrellab.protocols.SquirrelLabAutoRCProtocol %squirrellab.protocols.SquirrelLabAutoRCNoiseSineProtocol
    % Protocol to stimulate feedback to cones while voltage-clamping a
    % horizontal cell. Consists of a sum of 2 vSteps, first to -30 mV then
    % briefly to -90 mV (Vm in this protocol are defined in absolute value
    % instead of relative to holding potential).
    % Follows protocol from Warren, vanHook, et. al, J.NeuroSci (2016)
    properties
        amp                             % Output amplifier
        preTime = 1000                    % First pulse leading duration (ms)
        stimTime = 5000                 % First pulse duration (ms)
        tailTime = 1000                  % First pulse trailing duration (ms)
        
        delayTime = 2000                 % Second pulse delay duration from first pulse start (ms)
        stim2Time = 1000                 % Second pulse duration (ms)
        
        pulseLevel = -30                % First pulse absolute level (mV or pA)
        pulse2Level = -90                % Second pulse absolute level (mV or pA)
        numberOfAverages = uint16(3)    % Number of epochs
        interpulseInterval = 5          % Duration between epochs (s)
        
        frame
    end
    
    properties (Hidden)
        ampType
        frameType
        plotData
    end
    
    methods
        
        function didSetRig(obj)
%             didSetRig@squirrellab.protocols.SquirrelLabAutoRCNoiseSineProtocol(obj);
            didSetRig@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
            [obj.frame, obj.frameType] = obj.createDeviceNamesProperty('FrameMonitor');
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()obj.createAmpStimulus());
        end
        
        function prepareRun(obj)
            prepareRun@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj);
           
            obj.showFigure('squirrellab.figures.DataFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('squirrellab.figures.AverageFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('squirrellab.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @std}, ...
                'baselineRegion', [0 obj.preTime], ...
                'measurementRegion', [0 obj.preTime]);
            obj.showFigure('squirrellab.figures.ResponseFigure', obj.rig.getDevice(obj.frame));
            obj.showFigure('squirrellab.figures.ProgressFigure', obj.numberOfAverages);
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
        
        function stim = createAmpStimulus(obj)           
            g1 = symphonyui.builtin.stimuli.PulseGenerator();
            g1.preTime = obj.preTime;
            g1.stimTime = obj.stimTime;
            g1.tailTime = obj.tailTime;
            g1.amplitude = obj.pulseLevel-obj.rig.getDevice(obj.amp).background.quantity;
            g1.mean = obj.rig.getDevice(obj.amp).background.quantity;
            g1.sampleRate = obj.sampleRate;
            g1.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            pulse1=g1.generate();
            
            g2 = symphonyui.builtin.stimuli.PulseGenerator();
            g2.preTime = obj.preTime + obj.delayTime;
            g2.stimTime = obj.stim2Time;
            g2.tailTime = (obj.stimTime+obj.tailTime)-(obj.delayTime+obj.stim2Time);
            g2.amplitude = obj.pulse2Level+obj.pulseLevel-obj.rig.getDevice(obj.amp).background.quantity;
            g2.mean = 0;
            g2.sampleRate = obj.sampleRate;
            g2.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            pulse2=g2.generate();
            
            g=symphonyui.builtin.stimuli.SumGenerator();
            g.stimuli={pulse1,pulse2};
            
            stim=g.generate;
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj, epoch);
            if obj.runRC
                % Superclass runs RC epoch
            else %run normally
                % generate trigger
                trigger = obj.rig.getDevices('Trigger');
                if ~isempty(trigger)
                    epoch.addStimulus(trigger{1}, obj.createTriggerStimulus());
                end
            
                epoch.addStimulus(obj.rig.getDevice(obj.amp), obj.createAmpStimulus());
                epoch.addResponse(obj.rig.getDevice(obj.amp));
                epoch.addResponse(obj.rig.getDevice(obj.frame));
            end
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
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

