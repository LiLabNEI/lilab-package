classdef UvLCRStageProtocol < io.github.stage_vss.protocols.StageProtocol
    
    properties
%         amberLedIntensity = uint8(30);      % Intensity of amber LCR LED
%         uvLedIntensity = uint8(50);         % Intensity of UV LCR LED
%         blueLedIntensity = uint8(50);       % Intensity of blue LCR LED
%         centerOffset = [0, 0]               % Pattern [x, y] center offset (pixels)
          waitForLcrTrigger = false
    end
    
    properties (Hidden)
        lcr                                 % EKB Lightcrafter device
        lcrType
        
        %(Thanks Juan)
        lcrFrameTracker                     % lcr frame tracking (requires photodiode and enabling frameTracker)
        lcrFrameTrackerType
%         amberLedIntensityType = symphonyui.core.PropertyType('uint8', 'scalar', [0 30]);
%         uvLedIntensityType = symphonyui.core.PropertyType('uint8', 'scalar', [0 255]);
%         blueLedIntensityType = symphonyui.core.PropertyType('uint8', 'scalar', [0 255]);
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@io.github.stage_vss.protocols.StageProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
            [obj.lcr, obj.lcrType] = obj.createDeviceNamesProperty('LightCrafter');
            
            [obj.lcrFrameTracker, obj.lcrFrameTrackerType] = obj.createDeviceNamesProperty('lcrFrameTracker');
%             devices = obj.rig.getDevices('LightCrafter');
%             if isempty(devices)
%                 error('No LightCrafter device found');
%             end
%             lightCrafter = devices{1};
%             obj.centerOffset = lightCrafter.getCenterOffset();
        end
        
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@symphonyui.core.Protocol(obj, name);        
            
            
            
            % Can also set d.displayName, d.description
            if strncmp(name, 'numberOf',8) || any(strcmp(name, {'preTime','stimTime','tailTime','interpulseInterval','waitForLcrTrigger'}))
                d.category = 'Sweep Control';
                
                if contains(name, 'Time') || contains(name, 'Interval')
                    d.displayName = [d.displayName ' (ms)'];
                end
                
            elseif any(strcmp(name, {'sampleRate', 'amp'}))
                d.category = 'Amplifier';
                
                if contains(name, 'sampleRate')
                    d.displayName = [d.displayName ' (Hz)'];
                end
                
            elseif contains(name,'Led') || any(strcmp(name, {'centerOffset'}))
                d.category = 'Projector Control';
            else
                d.category = 'Protocol Parameters';
            end

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
            
            obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice(obj.lcrFrameTracker));
            obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('symphonyui.builtin.figures.MeanResponseFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('io.github.stage_vss.figures.FrameTimingFigure', obj.rig.getDevice('Stage'));
            
            
        end

        
        function p = addTrackerBarToFirstFrame(obj, p) %#ok<INUSL>
            
            trigger = stage.builtin.stimuli.Rectangle();
            trigger.size = [200, 1140];
            trigger.position = [912 + 850, 570];
            trigger.color = 1;
            p.addStimulus(trigger);
            
            triggerVis = stage.builtin.controllers.PropertyController(trigger, 'visible', @(s)(s.frame==0));
            p.addController(triggerVis); 
        end
        
                
        function p = addFrameTracker(obj, p, startTime, stopTime) %#ok<INUSL>
            
            tracker = stage.builtin.stimuli.Rectangle();
            tracker.size = [200, 1140];
            tracker.position = [912 + 850, 570];
            p.addStimulus(tracker);
            
            trackerColor = stage.builtin.controllers.PropertyController(tracker, 'color', @(s)mod(s.frame, 2) && double(s.time + (1/s.frameRate) < p.duration  &&  s.time >= startTime/1000.0  &&  s.time < stopTime/1000.0));
            trackerVis = stage.builtin.controllers.PropertyController(tracker, 'visible', @(s)(s.frame~=0));
            p.addController(trackerColor); 
            p.addController(trackerVis); 
            
        end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@io.github.stage_vss.protocols.StageProtocol(obj, epoch);
            
            epoch.addResponse(obj.rig.getDevice(obj.lcrFrameTracker));
            
            % Borrowed from sa-labs StageProtocol.m for testing:
            % uses the frame tracker on the monitor to inform the HEKA that
            % the stage presentation has begun. Improves temporal alignment
            epoch.shouldWaitForTrigger = obj.waitForLcrTrigger;
            
            % Set led currents from properties panel
%             lcrDev = obj.rig.getDevice(obj.lcr);
%             lcrDev.setLedCurrents(obj.amberLedIntensity, obj.uvLedIntensity, obj.blueLedIntensity);


            
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