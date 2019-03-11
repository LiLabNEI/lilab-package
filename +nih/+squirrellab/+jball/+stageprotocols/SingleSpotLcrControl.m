classdef SingleSpotLcrControl < io.github.stage_vss.protocols.StageProtocol
    
    properties
        amp                             % Output amplifier
        redLedIntensity = uint8(50);   % Intensity of red LCR LED
        greenLedIntensity = uint8(50); % Intensity of green LCR LED
        blueLedIntensity = uint8(50);  % Intensity of blue LCR LED
        preTime = 250                   % Spot leading duration (ms)
        stimTime = 4500                 % Spot duration (ms)
        tailTime = 250                  % Spot trailing duration (ms)
        spotIntensity = 1.0             % Spot light intensity (0-1)
        spotDiameter = 300              % Spot diameter size (pixels)
        backgroundIntensity = 0.0       % Background light intensity (0-1)
        centerOffset = [0, 0]           % Spot [x, y] center offset (pixels)
        numberOfAverages = uint16(5)    % Number of epochs
        interpulseInterval = 0          % Duration between spots (s)
    end
    
    properties (Hidden)
        ampType
        lcr                             % Lightcrafter device
        lcrType
        
        lcrDev
        
        redLedIntensityType = symphonyui.core.PropertyType('uint8', 'scalar', [0 130]);
        greenLedIntensityType = symphonyui.core.PropertyType('uint8', 'scalar', [0 130]);
        blueLedIntensityType = symphonyui.core.PropertyType('uint8', 'scalar', [0 130]);
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
        
        function p = createPresentation(obj)
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(obj.backgroundIntensity);
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.color = obj.spotIntensity;
            spot.radiusX = obj.spotDiameter/2;
            spot.radiusY = obj.spotDiameter/2;
            spot.position = canvasSize/2 - obj.centerOffset; % + obj.centerOffset - [450 0];
            p.addStimulus(spot);
            
            p0 = spot.position;
            
            function p = spotPosition(state) %#ok<INUSD>
                speed = 1000*900/obj.stimTime;
                p = p0 + [speed*state.time 0];   %spot.position + 5*randn(1,2);

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
            end
            
            function v = toggleVis(state)
                v = spot.visible;
                if state.time >= obj.preTime*1e-3 && v == false && state.time < (obj.preTime + obj.stimTime) * 1e-3
                    disp(['turning spot on @ t = ' num2str(state.time)]);
%                 state
                elseif state.time >= (obj.preTime + obj.stimTime) * 1e-3  && v == true
                    disp(['turning spot off @ t = ' num2str(state.time)]);
                    disp('');
                end
                
                v = state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3 ;
            end
            
            %Weird, kind of a hacky way to control the spot visibility (but
            %it works fine <shrug>)
            spotVisible = stage.builtin.controllers.PropertyController(spot, 'visible', @(state)toggleVis(state));
%             spotMove = stage.builtin.controllers.PropertyController(spot, 'position', @(state)spotPosition(state));
            
            spotSineModulate = stage.builtin.controllers.PropertyController(spot, 'color', @(state)[1 1 1]*(0.5+sin(1*pi*state.time)));
%             
            p.addController(spotVisible);
%             p.addController(spotSineModulate);
%             p.addController(spotMove);
%             p.addController(spotGrowX);
%             p.addController(spotGrowY);
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@io.github.stage_vss.protocols.StageProtocol(obj, epoch);
            
            device = obj.rig.getDevice(obj.amp);
            
            lcrDev = obj.rig.getDevice(obj.lcr);
            lcrDev.setLedCurrents(obj.redLedIntensity, obj.greenLedIntensity, obj.blueLedIntensity);
            
            
            
            duration = (obj.preTime + obj.stimTime + obj.tailTime) / 1e3;
            epoch.addDirectCurrentStimulus(device, device.background, duration, obj.sampleRate);
            epoch.addResponse(device);
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@io.github.stage_vss.protocols.StageProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
%             obj.lcr.setLedCurrents(obj.redLedIntensity, obj.greenLedIntensity, obj.blueLedIntensity);
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