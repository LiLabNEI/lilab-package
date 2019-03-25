classdef UvLCRStageProtocol < io.github.stage_vss.protocols.StageProtocol
    
    properties
        amberLedIntensity = uint8(30);      % Intensity of amber LCR LED
        uvLedIntensity = uint8(50);         % Intensity of UV LCR LED
        blueLedIntensity = uint8(50);       % Intensity of blue LCR LED
        centerOffset = [0, 0]               % Pattern [x, y] center offset (pixels)
    end
    
    properties (Hidden)
        lcr                                 % EKB Lightcrafter device
        lcrType

        amberLedIntensityType = symphonyui.core.PropertyType('uint8', 'scalar', [0 30]);
        uvLedIntensityType = symphonyui.core.PropertyType('uint8', 'scalar', [0 255]);
        blueLedIntensityType = symphonyui.core.PropertyType('uint8', 'scalar', [0 255]);
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@io.github.stage_vss.protocols.StageProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
            [obj.lcr, obj.lcrType] = obj.createDeviceNamesProperty('LightCrafter');
        end
        
        function p = getPreview(obj, panel)
            if isempty(obj.rig.getDevices('Stage'))
                p = [];
                return;
            end
            p = io.github.stage_vss.previews.StagePreview(panel, @()obj.createPresentation(), ...
                'windowSize', obj.rig.getDevice('Stage').getCanvasSize());
        end
        
        function prepareRun(obj)
            prepareRun@io.github.stage_vss.protocols.StageProtocol(obj);
            
            obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('symphonyui.builtin.figures.MeanResponseFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('io.github.stage_vss.figures.FrameTimingFigure', obj.rig.getDevice('Stage'));
        end

        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@io.github.stage_vss.protocols.StageProtocol(obj, epoch);
            
            % Should I also allow the setting of LED Enables here?
            
            % Set led currents from properties panel
            lcrDev = obj.rig.getDevice(obj.lcr);
            lcrDev.setLedCurrents(obj.amberLedIntensity, obj.uvLedIntensity, obj.blueLedIntensity);

        end
        
        function prepareInterval(obj, interval)
            prepareInterval@io.github.stage_vss.protocols.StageProtocol(obj, interval);
            
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
        %Override function "completeRun(obj)" to do stuff after running.
        
    end
    
end