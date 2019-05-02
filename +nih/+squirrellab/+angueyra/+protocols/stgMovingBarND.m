classdef stgMovingBarND < nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp
    % Moving bar stimulus with concatenated directions.
    % Created Apr_2019 (Angueyra)
    % Modified May_2019 (Angueyra): added a 2s itnerval between directiosn
    % by increasing barTotalTravel. Could produce some conflict with poech
    % beeing too long
    % Once analysis is settled, should make bar directions random and include non-moving flashing bars for comparison.
    
    properties
        preTime = 250                 % Bar leading duration (ms)
        tailTime = 250                % Bar trailing duration (ms)
        
        barSpeed = 500                % Bar speed (pix/s)
        barIntensity = 1.0              % Bar light intensity (0-1)
        backgroundIntensity = 0.0       % Background light intensity (0-1)
        
        barWidth = 50                  % bar width (pix)
        barHeight = 350                 % bar height (pix)
        barNDirections = 8              % Bar number of directions
        barStartDirection = 0           % Bar starting direction (degrees)
        
        barHorizontalPosition = 0       % Bar center relative to view center (px)
        barVerticalPosition = 0         % Bar center relative to view center (px)

        numberOfAverages = uint16(1)    % Number of epochs
        interpulseInterval = 0          % Duration between trials (s)
    end
    
    properties (Hidden)
        stimTime
        stimTime_oneBar
        barDirections
        barDirectionsRad
        barStartPosition = -1000;
        barTotalTravel; %barTotalTravel = 2000;
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj);
            obj.setStimTime();
        end
        
        function setStimTime(obj)
            obj.barTotalTravel = 2000 + (obj.barSpeed * 2); % adding a 2s interval between bars by extending bar travel.
            obj.stimTime_oneBar = ceil((obj.barTotalTravel + obj.barWidth)/(obj.barSpeed/1e3));
            obj.stimTime = obj.stimTime_oneBar * obj.barNDirections;
            fprintf('-----\n');
            fprintf('stimTime_oneBar = %3g s\n',obj.stimTime_oneBar*1e-3);
            fprintf('stimTime = %3g s\n',obj.stimTime*1e-3);
            fprintf('totalTime = %3g s\n',(obj.preTime + obj.stimTime + obj.tailTime)*1e-3);
            fprintf('-----\n');
            
            
        end
         
        
        function p = getPreview(obj, panel)
            obj.setStimTime();
            if isempty(obj.rig.getDevices('Stage'))
                p = [];
                return;
            end
            p = io.github.stage_vss.previews.StagePreview(panel, @()obj.createPresentation(), ...
                'windowSize', obj.rig.getDevice('Stage').getCanvasSize());
        end
        
        function prepareRun(obj)
            obj.setStimTime();
            prepareRun@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj);
        end
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj, name);        
            

            % Can also set d.displayName, d.description
            if contains(lower(name), 'bar') || contains(lower(name), 'background')
                d.category = 'Pattern stimulus';
                
                if contains(lower(name), 'width') || contains(lower(name), 'position') || contains(lower(name), 'height')
                    d.displayName = [d.displayName ' (pixels)'];
                elseif contains(lower(name), 'intensity')
                    d.displayName = [d.displayName ' [0-1]'];
                elseif contains(lower(name), 'start')
                    d.displayName = [d.displayName ' (degrees)'];
                elseif contains(lower(name), 'speed')
                    d.displayName = [d.displayName ' (pixels/s)'];
                end

                %No default behavior; is handled in superclass
            end

        end 
        
        function p = createPresentation(obj)
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            
            obj.barDirections = (0:360/obj.barNDirections:359)+obj.barStartDirection;
            obj.barDirections = mod(obj.barDirections,360);
            obj.barDirectionsRad = obj.barDirections/180*pi;


            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(obj.backgroundIntensity);
            
            bar = stage.builtin.stimuli.Rectangle();
            bar.color = obj.barIntensity;
            bar.size = [obj.barWidth, obj.barHeight];
            bar.orientation = obj.barStartDirection;
            bar.position = canvasSize/2.0 + [obj.barHorizontalPosition obj.barVerticalPosition];
            p.addStimulus(bar);
            
            function v = toggleVis(state)
                v = state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3 ;
            end
            
            barVisible = stage.builtin.controllers.PropertyController(bar, 'visible', @(state)toggleVis(state));
            p.addController(barVisible);
            
            % Bar orientation controller
            function o = orientationTable(obj, time)
                if time <= obj.preTime * 1e-3
                    barN = 1;
                elseif time > obj.preTime * 1e-3 && time < (obj.preTime + obj.stimTime) * 1e-3                    
                    barN = ceil( (time - (obj.preTime*1e-3)) / (obj.stimTime_oneBar * 1e-3) );
                else
                    barN=1; %obj.barNDirections;
                end
                o = obj.barDirections(barN);
%                 o = obj.barDirections(1);
%                 fprintf('time = %g, orientation = %g\n', time, o)
            end            
            barOrientationController = stage.builtin.controllers.PropertyController(bar, 'orientation', ...
                @(state)orientationTable(obj, state.time));
            p.addController(barOrientationController);
           
%             % Bar position and orientation controller
            function h = motionTable(obj, time)
                % Calculate the increment with time.  
                if time <= obj.preTime * 1e-3
                    barN = 1;
                    inc = obj.barStartPosition - obj.barWidth; 
                elseif time > obj.preTime * 1e-3 && time < (obj.preTime + obj.stimTime) * 1e-3                    
                    barN = ceil( (time - (obj.preTime*1e-3)) / (obj.stimTime_oneBar * 1e-3) );
                    inc = mod(time - (obj.preTime*1e-3),(obj.stimTime_oneBar/1e3)) * obj.barSpeed + obj.barStartPosition - obj.barWidth; %reset increments at every bar switch
                else
                    barN=1; %obj.barNDirections;
                    inc = obj.barStartPosition - obj.barWidth;
                end
                h = [cos(obj.barDirectionsRad(barN)) sin(obj.barDirectionsRad(barN))] .* (inc*ones(1,2)) + canvasSize/2 + [obj.barHorizontalPosition obj.barVerticalPosition];
%                 fprintf('time = %g, position = %g, %g\n', time, h)
            end
            
            barPositionController = stage.builtin.controllers.PropertyController(bar, 'position', ...
                @(state)motionTable(obj, state.time));
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