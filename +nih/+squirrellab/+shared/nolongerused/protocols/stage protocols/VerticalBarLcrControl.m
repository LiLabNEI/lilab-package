classdef VerticalBarLcrControl < nih.squirrellab.shared.protocols.UvLCRStageProtocol
    
    properties
        amp                             % Output amplifier
        preTime = 250                   % bar leading duration (ms)
        stimTime = 1500                 % bar duration (ms)
        tailTime = 250                  % bar trailing duration (ms)
        barIntensity = 1.0              % bar light intensity (0-1)
        barWidth = 100                  % In pixels
        backgroundIntensity = 0.0       % Background light intensity (0-1)
        
        numberOfAverages = uint16(1)    % Number of epochs
        interpulseInterval = 0          % Duration between bars (s)
    end
    
    
    properties (Hidden)
        ampType
    end
    
    
    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj);

            
        end
        

        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj);
            
        end
        
        function p = createPresentation(obj)
            
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(obj.backgroundIntensity);
            
            bar = stage.builtin.stimuli.Rectangle();
            bar.color = obj.barIntensity;
            bar.size = [obj.barWidth, canvasSize(2)];
            bar.position = canvasSize/2 + obj.centerOffset;
            p.addStimulus(bar);
            

            function v = toggleVis(state)
                v = state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3 ;
            end
            
            barVisible = stage.builtin.controllers.PropertyController(bar, 'visible', @(state)toggleVis(state));
            p.addController(barVisible);
            
        end
        
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj, epoch);
            
            device = obj.rig.getDevice(obj.amp);
            
            duration = (obj.preTime + obj.stimTime + obj.tailTime) / 1e3;
            epoch.addDirectCurrentStimulus(device, device.background, duration, obj.sampleRate);
            epoch.addResponse(device);
        end
        
        
        
        
        function prepareInterval(obj, interval)
            prepareInterval@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        
        
    end
    
end