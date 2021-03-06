classdef stgMovingBar < nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp
    % Creates a moving bar that starts 500 pixels away from center. 
    % 00 deg = Left-Right
    % 90 deg = Up-Down
    properties
        preTime = 00500                 % Bar leading duration (ms)
        stimTime = 02000                % Bar duration (ms)
        tailTime = 01500                % Bar trailing duration (ms)
        
        barSpeed = 02000                % Bar speed (pix/s)
        barIntensity = 1.0              % Bar light intensity (0-1)
        backgroundIntensity = 0.0       % Background light intensity (0-1)
        
        barWidth = 100                  % bar width (pix)
        barHeight = 100                 % bar height (pix)
        barDirection = 0                % Bar direction in degrees
        
        barHorizontalPosition = 0       % Bar center relative to view center (px)
        barVerticalPosition = 0         % Bar center relative to view center (px)

        numberOfAverages = uint16(1)    % Number of epochs
        interpulseInterval = 0          % Duration between trials (s)
    end
    
    properties (Hidden)
        barDirectionRad
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj);
            
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
            prepareRun@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj);

        end
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj, name);        
            

            % Can also set d.displayName, d.description
            if contains(lower(name), 'bar') || contains(lower(name), 'background')
                d.category = 'Pattern stimulus';
                
                if contains(lower(name), 'width') || contains(lower(name), 'position')
                    d.displayName = [d.displayName ' (pixels)'];
                elseif contains(lower(name), 'intensity')
                    d.displayName = [d.displayName ' [0-1]'];
                elseif contains(lower(name), 'direction')
                    d.displayName = [d.displayName ' (degrees)'];
                end

                %No default behavior; is handled in superclass
            end

        end 
        
        function p = createPresentation(obj)
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            obj.barDirectionRad = obj.barDirection/180*pi;
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(obj.backgroundIntensity);
            
            bar = stage.builtin.stimuli.Rectangle();
            bar.color = obj.barIntensity;
            bar.size = [obj.barWidth, obj.barHeight];
            bar.orientation = obj.barDirection;
            bar.position = canvasSize/2.0 + [obj.barHorizontalPosition obj.barVerticalPosition];
            p.addStimulus(bar);
            
            function v = toggleVis(state)
                v = state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3 ;
            end
            
            barVisible = stage.builtin.controllers.PropertyController(bar, 'visible', @(state)toggleVis(state));
            p.addController(barVisible);
            
            
            
            % Create a controller to change the bar's position property as a function of time.
            % Bar position controller
            function h = motionTable(obj, time)
                % Calculate the increment with time.  
                inc = time * obj.barSpeed - 500 - obj.barWidth;
                
                h = [cos(obj.barDirectionRad) sin(obj.barDirectionRad)] .* (inc*ones(1,2)) + canvasSize/2 + [obj.barHorizontalPosition obj.barVerticalPosition];
            end
            
            barPositionController = stage.builtin.controllers.PropertyController(bar, 'position', ...
                @(state)motionTable(obj, state.time - (obj.preTime)*1e-3));
            p.addController(barPositionController);
            
            
            p = obj.addFrameTracker(p);
            p = obj.addTrackerBarToFirstFrame(p);
            
        end
        
        function p = addFrameTracker(obj, p) 
            p = addFrameTracker@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj, p, obj.preTime, obj.preTime + obj.stimTime);
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj, epoch);
            
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj, interval);            
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