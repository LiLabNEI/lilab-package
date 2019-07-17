classdef stgRFMapBars < nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp
    % Flashing bars to map Receptive Fields.
	% Assumes cells are relatively centered respect to stimulus and flashes bars
	% in opposite directions according to span, and in n orientations
    % Created July_2019 (Angueyra)
    % Once analysis is settled, should make bar location/direction random
    
    properties
        preTime = 10000                 % Stimulus leading duration (ms)
        tailTime = 10000                % Stimulus trailing duration (ms)
        barStimTime = 2000				% Stimulus duration per bar (ms)
		barInterval = 3000				% Duration between bars (ms)
        barIntensity = 1.0              % Bar light intensity (0-1)
        backgroundIntensity = 0.0       % Background light intensity (0-1)
        
		
        barWidth = 50                   % bar width (pix)
        barHeight = 350                 % bar height (pix)
		barSpan = 1000					% limits (pix) of gridded space where bars will be flashed
        barNOrientation = uint16(2)     % Bar number of orientation
        barStartOrientation = 0         % Bar starting orientation (degrees)
        
        barHorizontalPosition = 0       % Bar center relative to view center (px)
        barVerticalPosition = 0         % Bar center relative to view center (px)

        numberOfAverages = uint16(1)    % Number of epochs
        interpulseInterval = 0          % Duration between trials (s)
    end
    
    properties (Hidden)
        stimTime
		stimTime_oneBar
		
		barN
		barPositions
        barOrientations
        barOrientationsRad
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj);
            obj.setStimTime();
        end
        
        function setStimTime(obj)
            obj.barNOrientation = double(obj.barNOrientation);
			obj.barN = ceil(obj.barSpan / obj.barWidth);
			obj.stimTime_oneBar = (obj.barStimTime + obj.barInterval);
            obj.stimTime = obj.stimTime_oneBar * obj.barN * obj.barNOrientation;
            fprintf('-----\n');
            fprintf('stimTime_oneBar = %3g s\n',obj.stimTime_oneBar*1e-3);
            fprintf('bar number = %3g\n',obj.barN);
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
                
                if contains(lower(name), 'width') || contains(lower(name), 'position') || contains(lower(name), 'height') || contains(lower(name), 'span')
                    d.displayName = [d.displayName ' (pixels)'];
                elseif contains(lower(name), 'intensity')
                    d.displayName = [d.displayName ' [0-1]'];
                elseif contains(lower(name), 'startorientation')
                    d.displayName = [d.displayName ' (degrees)'];
                elseif contains(lower(name), 'speed')
                    d.displayName = [d.displayName ' (pixels/s)'];
                end

                %No default behavior; is handled in superclass
            end

        end 
        
        function p = createPresentation(obj)
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();

			obj.barPositions = ([0:1:obj.barN]*obj.barWidth) - floor(obj.barSpan/2);
            obj.barOrientations = ([0:180/obj.barNOrientation:179])+obj.barStartOrientation;
            obj.barOrientations = mod(obj.barOrientations,180);
            obj.barOrientationsRad = obj.barOrientations/180*pi;
            
%             fprintf('bar orientations = %3g\n',obj.barOrientations);
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(obj.backgroundIntensity);
            
            bar = stage.builtin.stimuli.Rectangle();
            bar.color = obj.barIntensity;
            bar.size = [obj.barWidth, obj.barHeight];
            bar.orientation = obj.barOrientations(1);
            bar.position = canvasSize/2.0 + [obj.barHorizontalPosition obj.barVerticalPosition];
            p.addStimulus(bar);
            
            % Bar position controller 
			% (order of operations here? does orientation controller operate after position controller? -> yes? go to moving bars stim)
            function h = positionTable(obj, time)
                barNumber = 1;
                barOrientation = obj.barOrientations(barNumber);
                if time > obj.preTime * 1e-3 && time < (obj.preTime + obj.stimTime) * 1e-3
                    barNumber = ceil( (time - (obj.preTime*1e-3)) / (obj.stimTime_oneBar * 1e-3) );
                    barNumber = mod(barNumber-1, obj.barNOrientation)+1;
                    barOrientation = obj.barOrientations( ceil(barNumber/obj.barNOrientation) );
                end
                h = [cos(barOrientation) sin(barOrientation)] .* [obj.barPositions(barNumber),0] + canvasSize/2 + [obj.barHorizontalPosition obj.barVerticalPosition];
            end
            
            barPositionController = stage.builtin.controllers.PropertyController(bar, 'position', ...
                @(state)positionTable(obj, state.time));
            p.addController(barPositionController);
			

            % Bar visibility controller
            function v = toggleVis(obj, time)
                v = 0;
                if time > obj.preTime * 1e-3 && time < (obj.preTime + obj.stimTime) * 1e-3
                    barIntrinsicTime = mod(time - (obj.preTime*1e-3),(obj.stimTime_oneBar/1e3));
                    if barIntrinsicTime <= obj.barStimTime * 1e-3
                        v = 1;
                    end
                else
                    v = 0;
                end
            end
            barVisible = stage.builtin.controllers.PropertyController(bar, 'visible', @(state)toggleVis(obj,state.time));
            p.addController(barVisible);
			
            
            % Bar orientation controller
            function o = orientationTable(obj, time)
                barNumber = 1;
                if time > obj.preTime * 1e-3 && time < (obj.preTime + obj.stimTime) * 1e-3
                    barNumber = ceil( (time - (obj.preTime*1e-3)) / (obj.stimTime_oneBar * 1e-3) );
                    barNumber = ceil(barNumber/obj.barNOrientation);
                end
                o = obj.barOrientations(barNumber);
            end
            barOrientationController = stage.builtin.controllers.PropertyController(bar, 'orientation', ...
                @(state)orientationTable(obj, state.time));
            p.addController(barOrientationController);
            
            
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