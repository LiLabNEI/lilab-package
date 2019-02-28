classdef vRamp < squirrellab.protocols.SquirrelLabAutoRCProtocol %squirrellab.protocols.SquirrelLabAutoRCNoiseSineProtocol
    
    properties
        amp                             % Output amplifier
        preTime = 50                    % Ramp leading duration (ms)
        stimTime = 500                  % Ramp duration (ms)
        tailTime = 3000                   % Ramp trailing duration (ms)
        rampStart = -120                % Ramp amplitude (mV or pA)
        rampEnd = 50                    % Ramp amplitude (mV or pA)
        numberOfAverages = uint16(3)    % Number of epochs
        interpulseInterval = 0.2          % Duration between ramps (s)
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
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()obj.createAmpStimulus());
        end
        
        function prepareRun(obj)
            prepareRun@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj);
           
            obj.showFigure('squirrellab.figures.DataFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('squirrellab.figures.AverageFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('squirrellab.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @std}, ...
                'baselineRegion', [0 obj.preTime], ...
                'measurementRegion', [0 obj.preTime]);
            obj.showFigure('squirrellab.figures.ProgressFigure', obj.numberOfAverages);
        end
        
        function stim = createAmpStimulus(obj)
            g1 = symphonyui.builtin.stimuli.RampGenerator();
            
            g1.preTime = obj.preTime;
            g1.stimTime = obj.stimTime;
            g1.tailTime = obj.tailTime;
            g1.amplitude = obj.rampEnd-obj.rampStart;
            g1.mean = obj.rampStart;
            g1.sampleRate = obj.sampleRate;
            g1.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            ramp = g1.generate();
                       
            g2 = symphonyui.builtin.stimuli.PulseGenerator();
            
            g2.preTime = 0;
            g2.stimTime = obj.preTime;
            g2.tailTime = obj.stimTime + obj.tailTime;
            g2.amplitude = obj.rig.getDevice(obj.amp).background.quantity-obj.rampStart;
            g2.mean = 0;
            g2.sampleRate = obj.sampleRate;
            g2.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            pulse1=g2.generate();
            
            g3 = symphonyui.builtin.stimuli.PulseGenerator();
            
            g3.preTime = obj.preTime + obj.stimTime;
            g3.stimTime = obj.tailTime;
            g3.tailTime = 0;
            g3.amplitude = obj.rig.getDevice(obj.amp).background.quantity-obj.rampStart;
            g3.mean = 0;
            g3.sampleRate = obj.sampleRate;
            g3.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            pulse2=g3.generate();

            
            g=symphonyui.builtin.stimuli.SumGenerator();
            g.stimuli={ramp,pulse1,pulse2};
            
            stim=g.generate;
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj, epoch);
            if obj.runRC
                % Superclass runs RC epoch
            else %run normally
                epoch.addStimulus(obj.rig.getDevice(obj.amp), obj.createAmpStimulus());
                epoch.addResponse(obj.rig.getDevice(obj.amp));
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

