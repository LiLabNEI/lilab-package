classdef VerticalBar < nih.squirrellab.shared.protocols.UvLCRStageProtocol
    
    properties
        amp                             % Output amplifier
        preTime = 250                   % Bar leading duration (ms)
        stimTime = 1500                 % Bar duration (ms)
        tailTime = 250                  % Bar trailing duration (ms)
        barIntensity = 1.0              % Bar light intensity (0-1)
        barWidth = 100                  % bar width in px
        backgroundIntensity = 0.0       % Background light intensity (0-1)
        barHorizontalPosition = 0       % Bar center relative to view center (px)
        
        
        numberOfAverages = uint16(1)    % Number of epochs
        interpulseInterval = 0          % Duration between trials (s)
    end
    
    properties (Hidden)
        ampType
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@io.github.stage_vss.protocols.StageProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
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
        
        
        
                function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj, name);        
            

            % Can also set d.displayName, d.description
            if contains(lower(name), 'bar') || contains(lower(name), 'background')
                d.category = 'Pattern stimulus';
                
                if contains(lower(name), 'width') || contains(lower(name), 'position')
                    d.displayName = [d.displayName ' (pixels)'];
                elseif contains(lower(name), 'intensity')
                    d.displayName = [d.displayName ' [0-1]'];
                end

                %No default behavior; is handled in superclass
            end

        end 
        
        
        
        function p = createPresentation(obj)
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(obj.backgroundIntensity);
            
            bar = stage.builtin.stimuli.Rectangle();
            bar.color = obj.barIntensity;
            bar.size = [obj.barWidth, canvasSize(2)];
            bar.position = canvasSize/2.0 + [obj.barHorizontalPosition 0];
            p.addStimulus(bar);
            
            
  
            function v = toggleVis(state)
                v = state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3 ;
            end
            
            barVisible = stage.builtin.controllers.PropertyController(bar, 'visible', @(state)toggleVis(state));
            p.addController(barVisible);
            
            p = addFrameTracker(obj, p);
            
        end
        
        function p = addFrameTracker(obj, p) 
            p = addFrameTracker@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj, p, obj.preTime, obj.preTime + obj.stimTime);
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@io.github.stage_vss.protocols.StageProtocol(obj, epoch);
            
            device = obj.rig.getDevice(obj.amp);
            
            duration = (obj.preTime + obj.stimTime + obj.tailTime) / 1e3;
            epoch.addDirectCurrentStimulus(device, device.background, duration, obj.sampleRate);
            epoch.addResponse(device);
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@io.github.stage_vss.protocols.StageProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
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