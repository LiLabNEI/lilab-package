classdef Ramp < nih.squirrellab.shared.protocols.SquirrelLabProtocol
    % Presents a set of ramp stimuli to a specified amplifier and records from the same amplifier.
    
    properties
        amp                             % Output amplifier
        preTime = 50                    % Ramp leading duration (ms)
        stimTime = 500                  % Ramp duration (ms)
        tailTime = 50                   % Ramp trailing duration (ms)
        rampAmplitude = 100             % Ramp amplitude (mV or pA depending on amp mode)
    end
    
    properties (Dependent, SetAccess = private)
        amp2                            % Secondary amplifier
    end
    
    properties
        numberOfAverages = uint16(5)    % Number of epochs
        interpulseInterval = 0          % Duration between ramps (s)
    end
    
    properties (Hidden)
        ampType
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, name);
            
            if strncmp(name, 'amp2', 4) && numel(obj.rig.getDeviceNames('Amp')) < 2
                d.isHidden = true;
            end
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()obj.createAmpStimulus());
        end
        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            if numel(obj.rig.getDeviceNames('Amp')) < 2
                obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice(obj.amp));
                obj.showFigure('symphonyui.builtin.figures.MeanResponseFigure', obj.rig.getDevice(obj.amp));
                obj.showFigure('symphonyui.builtin.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, ...
                    'baselineRegion', [0 obj.preTime], ...
                    'measurementRegion', [obj.preTime obj.preTime+obj.stimTime]);
            else
                obj.showFigure('nih.squirrellab.shared.figures.DualResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2));
                obj.showFigure('nih.squirrellab.shared.figures.DualMeanResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2));
                obj.showFigure('nih.squirrellab.shared.figures.DualResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, obj.rig.getDevice(obj.amp2), {@mean, @var}, ...
                    'baselineRegion1', [0 obj.preTime], ...
                    'measurementRegion1', [obj.preTime obj.preTime+obj.stimTime], ...
                    'baselineRegion2', [0 obj.preTime], ...
                    'measurementRegion2', [obj.preTime obj.preTime+obj.stimTime]);
            end
        end
        
        function stim = createAmpStimulus(obj)
            gen = symphonyui.builtin.stimuli.RampGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.amplitude = obj.rampAmplitude;
            gen.mean = obj.rig.getDevice(obj.amp).background.quantity;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, epoch);
            
            epoch.addStimulus(obj.rig.getDevice(obj.amp), obj.createAmpStimulus());
            epoch.addResponse(obj.rig.getDevice(obj.amp));
            
            if numel(obj.rig.getDeviceNames('Amp')) >= 2
                epoch.addResponse(obj.rig.getDevice(obj.amp2));
            end
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
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

