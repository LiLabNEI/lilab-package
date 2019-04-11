classdef SingleSpotLcrControl < nih.squirrellab.shared.protocols.UvLCRStageProtocol
    
    properties
        amp                             % Output amplifier
        preTime = 250                   % Spot leading duration (ms)
        stimTime = 1500                 % Spot duration (ms)
        tailTime = 250                  % Spot trailing duration (ms)
        spotIntensity = 1.0             % Spot light intensity (0-1)
        spotDiameter = 300              % Spot diameter size (pixels)
        backgroundIntensity = 0.0       % Background light intensity (0-1)
        
        numberOfAverages = uint16(1)    % Number of epochs
        interpulseInterval = 0          % Duration between spots (s)
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
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.color = obj.spotIntensity;
            spot.radiusX = obj.spotDiameter/2;
            spot.radiusY = obj.spotDiameter/2;
            spot.position = canvasSize/2;% + obj.centerOffset;
            p.addStimulus(spot);
            

            function v = toggleVis(state)
                v = state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3 ;
            end
            
            spotVisible = stage.builtin.controllers.PropertyController(spot, 'visible', @(state)toggleVis(state));
            p.addController(spotVisible);
            
            p = addFrameTracker(obj, p);
            
        end
        
        function p = addFrameTracker(obj, p) 
            p = addFrameTracker@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj, p, obj.preTime, obj.preTime + obj.stimTime);
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