classdef CalibrationSpot < nih.squirrellab.shared.protocols.UvLCRStageProtocol
    
    properties
        amp                             % Output amplifier
        
        spotDiameter = uint16(250)              % Spot diameter size (pixels)
        
        spotCenterX = int16(0)             % Horizontal center of spot (pixels)
        spotCenterY = int16(0)             % Vertical center of spot (pixels)
    end
    
    
    properties (Hidden)
        ampType
        statusFigure
        backgroundIntensity = 0.0       % Background light intensity (0-1)
        spotDiameterType = symphonyui.core.PropertyType('uint16', 'scalar', [0 1000])
        spotCenterXType = symphonyui.core.PropertyType('int16', 'scalar', [-100 100])
        spotCenterYType = symphonyui.core.PropertyType('int16', 'scalar', [-100 100])
    end

    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj);

            devices = obj.rig.getDevices('LightCrafter');
            if isempty(devices)
                error('No LightCrafter device found');
            end
            lightCrafter = devices{1};
            obj.spotDiameter = uint16(lightCrafter.um2pix(100.0));
        end
        

        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj);
            
        end
        
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj, name);        
            

            % Can also set d.displayName, d.description
            if strcmp(d.category, 'Amplifier')
               d.isHidden = true; 
            end
            
            if contains(lower(name), 'spot')
                d.category = 'Spot size & location in LCR pixels';
                
                if contains(lower(name), 'diameter')
                    d.displayName = [d.displayName ' (pixels)'];
                elseif strcmp(name, 'spotCenterX')
                    d.displayName = ['Additional X offset'];
                elseif strcmp(name, 'spotCenterY')
                    d.displayName = ['Additional Y offset'];
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
            spot.radiusX = double(obj.spotDiameter)/2.0;
            spot.radiusY = double(obj.spotDiameter)/2.0;
            spot.position = canvasSize/2 + double([obj.spotCenterX obj.spotCenterY]);
            p.addStimulus(spot);            
        end

        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.UvLCRStageProtocol(obj, epoch);
            
            device = obj.rig.getDevice(obj.amp);
            
            duration = 0.250;
            
            devices = obj.rig.getDevices('LightCrafter');
            if isempty(devices)
                error('No LightCrafter device found');
            end
            lightCrafter = devices{1};
            
            previousOffset = lightCrafter.getCenterOffset();
            
            tempMicronsPerPixel = 100.0/double(obj.spotDiameter);
            tempCenterX = tempMicronsPerPixel * (double(obj.spotCenterX) + previousOffset(1));
            tempCenterY = tempMicronsPerPixel * (double(obj.spotCenterY) + previousOffset(2));
            
            clc
            fprintf('Current calibration: Center offset (um): X = %3.4f, Y = %3.4f, um/px = %3.4f\n', tempCenterX, tempCenterY, tempMicronsPerPixel);
            
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
%        
%         function completeRun(obj)
%            
%             disp('completeRun was called.');
%             
%         end
        
    end
    
end