classdef CalibrationSpot < nih.squirrellab.shared.protocols.UvLCRStageProtocol
    
    properties
        amp                             % Output amplifier
        
        spotDiameter = 250              % Spot diameter size (pixels)
        backgroundIntensity = 0.0       % Background light intensity (0-1)
        spotCenter = [0, 0]             % Center of spot (pixels)
    end
    
    
    properties (Hidden)
        ampType
        statusFigure
    end

    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj);

            
        end
        

        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj);
            
            %Generously steal from prepareRun@SealTest here
            
        end
        
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj, name);        
            

            % Can also set d.displayName, d.description
            if contains(lower(name), 'spot') || contains(lower(name), 'background')
                d.category = 'Pattern stimulus';
                
                if contains(lower(name), 'diameter') || contains(lower(name), 'center')
                    d.displayName = [d.displayName ' (pixels)'];
                elseif contains(lower(name), 'intensity')
                    d.displayName = [d.displayName ' [0-1]'];
                end

                %No default behavior; is handled in superclass
            end

        end 
        
        
        function p = createPresentation(obj)
            
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            
            p = stage.core.Presentation(1); %1 second
            p.setBackgroundColor(obj.backgroundIntensity);
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.color = 1;
            spot.radiusX = obj.spotDiameter/2;
            spot.radiusY = obj.spotDiameter/2;
            spot.position = canvasSize/2 + obj.spotCenter;
            p.addStimulus(spot);
            

%             function v = toggleVis(state)
%                 v = state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3 ;
%             end
            
            
%             function p = spotPosition(state)
% 			
%                 p = obj.spotCenter;
% 			
%                 if window.getKeyState(GLFW.GLFW_KEY_UP)
%                     p(2) = p(2) + 1;
%                 end
%                 if window.getKeyState(GLFW.GLFW_KEY_DOWN)
%                     p(2) = p(2) - 1;
%                 end
%                 if window.getKeyState(GLFW.GLFW_KEY_LEFT)
%                     p(1) = p(1) - 1;
%                 end
%                 if window.getKeyState(GLFW.GLFW_KEY_RIGHT)
%                     p(1) = p(1) + 1;
%                 end
%                 
%                 obj.spotCenter = p;
%             end
            
            
            
%             spotVisible = stage.builtin.controllers.PropertyController(spot, 'visible', @(state)toggleVis(state));
%             p.addController(spotVisible);
            
%             spotMove = stage.builtin.controllers.PropertyController(spot, 'position', @(state)spotPosition(state));
%             p.addController(spotMove);
            
        end

        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj, epoch);
            
            device = obj.rig.getDevice(obj.amp);
            
            duration = 1.0;
            epoch.addDirectCurrentStimulus(device, device.background, duration, obj.sampleRate);
            epoch.addResponse(device);
        end
        
        
        
        
        function prepareInterval(obj, interval)
            prepareInterval@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
            interval.addDirectCurrentStimulus(device, device.background, 0.0, obj.sampleRate);
        end
        
        
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < 1;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < 1;
        end
       
        function completeRun(obj)
           
            disp('completeRun was called.');
            
        end
        
    end
    
end