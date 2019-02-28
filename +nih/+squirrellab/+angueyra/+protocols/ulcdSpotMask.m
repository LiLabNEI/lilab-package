classdef ulcdSpotMask < squirrellab.protocols.SquirrelLabStageProtocol %io.github.stage_vss.protocols.StageProtocol
    % Display a spot mask on uLCD permanently until cleared
    properties
        amp                             % Output amplifier
        ulcd                            % uLCD screen
        centerX = 114                   % Spot x center (pixels)
        centerY = 118                   % Spot y center (pixels)
        spotRadius = 3                  % Spot radius size (pixels)
    end
    
    properties (Hidden)
        ampType
        ulcdType
        preTime = 20                    % Spot leading duration (ms)
        stimTime = 20                   % Spot duration (ms)
        tailTime = 20                   % Spot trailing duration (ms)
        numberOfAverages = uint16(1)    % Number of epochs
        interpulseInterval = 0          % Duration between spots (s)
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@io.github.stage_vss.protocols.StageProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
            [obj.ulcd, obj.ulcdType] = obj.createDeviceNamesProperty('uLCD');
        end
        
        function prepareRun(obj)
            prepareRun@io.github.stage_vss.protocols.StageProtocol(obj);
        end

        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(0);
            
            uStim=squirrellab.stimuli.uLCDMaskSpotGenerator();
            uStim.centerX=obj.centerX;
            uStim.centerY=obj.centerY;
            uStim.preTime=obj.preTime*1e-3;
            uStim.stimTime=obj.stimTime*1e-3;
            uStim.tailTime=obj.tailTime*1e-3;
            uStim.spotRadius=obj.spotRadius;
            p.addStimulus(uStim);
            
            uLCDCMD = stage.builtin.controllers.PropertyController(uStim, 'cmdCount', @(state)squirrellab.stage2.uLCDMaskSpotController(state));
            p.addController(uLCDCMD);
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
        
    end
    
end

