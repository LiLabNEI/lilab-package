classdef ulcdGridSpot < squirrellab.protocols.SquirrelLabStageProtocol %io.github.stage_vss.protocols.StageProtocol
    % Creates an led pulsecombined with a uLCD spots laid on a grid.
    % Grid's origin at startX and startY
    % Spot is created during preTime, cleared during tailTime
    % Default values create a 3 x 3 grid with perfectly adjacent spots
    
    properties
        amp                             % Output amplifier
        led                             % Output LED
        ulcd                            % uLCD screen
        preTime = 200                   % Spot leading duration (ms)
        stimTime = 100                 % Spot duration (ms)
        tailTime = 500                  % Spot trailing duration (ms)
        
        spotRadius = 3               % Spot radius size (pixels)
        
        startX = 114                   % Spot x center (pixels)
        startY = 118                   % Spot y center (pixels)
        
        deltaX = 6                   % Spot x center (pixels)
        deltaY = 6                   % Spot y center (pixels)
        
        nX = 5                   % Spot x center (pixels)
        nY = 5                   % Spot y center (pixels)
        
        ledAmplitude = 8
        ledMean = 0
        
        numberOfAverages = uint16(1)    % Number of epochs
        interpulseInterval = 0          % Duration between spots (s)
        
        randomOrder = false
    end
    
    properties (Hidden)
        ampType
        ledType
        ulcdType
        currentX
        currentY
        sequenceX
        sequenceY
        gridPatternX
        gridPatternY
        randOrder
        nTotal
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@io.github.stage_vss.protocols.StageProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
            [obj.led, obj.ledType] = obj.createDeviceNamesProperty('LED');
            [obj.ulcd, obj.ulcdType] = obj.createDeviceNamesProperty('uLCD');
        end
        
%         function p = getPreview(obj, panel)
%             if isempty(obj.rig.getDevices('Stage'))
%                 p = [];
%                 return;
%             end
%             p = io.github.stage_vss.previews.StagePreview(panel, @()obj.createPresentation(), ...
%                 'windowSize', obj.rig.getDevice('Stage').getCanvasSize());
%         end
        
        function prepareRun(obj)
            prepareRun@io.github.stage_vss.protocols.StageProtocol(obj);
            
            obj.gridPatternX = repmat(-(obj.nX-1)/2:(obj.nX-1)/2,1,obj.nY);
            obj.gridPatternY = sort(repmat(-(obj.nY-1)/2:(obj.nY-1)/2,1,obj.nX));
            obj.sequenceX = obj.startX + (obj.gridPatternX .* obj.deltaX);
            obj.sequenceY = obj.startY + (obj.gridPatternY .* obj.deltaY);
            obj.nTotal = obj.nX * obj.nY;
            
            if obj.randomOrder
               obj.randOrder = randsample(obj.nTotal, obj.nTotal);
               obj.sequenceX = obj.sequenceX(obj.randOrder);
               obj.sequenceY = obj.sequenceY(obj.randOrder);
            else
                obj.randOrder=1:obj.nTotal;
            end
            
%             obj.showFigure('squirrellab.figures.DataFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('squirrellab.figures.uLCDGridResponseFigure', obj.rig.getDevice(obj.amp),...
                'prepts',obj.timeToPts(obj.preTime),...
                'stmpts',obj.timeToPts(obj.stimTime),...
                'datapts',obj.timeToPts(obj.preTime+obj.stimTime+obj.tailTime),...
                'gridPatternX',obj.gridPatternX,...
                'gridPatternY',obj.gridPatternY,...
                'randOrder',obj.randOrder,...
                'nX',obj.nX,...
                'nY',obj.nY,...
                'nTrials',obj.nTotal);
            obj.showFigure('squirrellab.figures.uLCDgridRFFigure', obj.rig.getDevice(obj.amp),...
                'prepts',obj.timeToPts(obj.preTime),...
                'stmpts',obj.timeToPts(obj.stimTime),...
                'delaypts',obj.timeToPts(50/1000),...
                'spotRadius',obj.spotRadius,...
                'sequenceX',obj.sequenceX,...
                'sequenceY',obj.sequenceY,...
                'nTrials',obj.nTotal);
        end
        
        function stim = createLedStimulus(obj)
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.amplitude = obj.ledAmplitude;
            gen.mean = obj.ledMean;
            gen.sampleRate = obj.sampleRate;
            gen.units = 'V';
            
            stim = gen.generate();
        end
        
        
        function p = createPresentation(obj)
%           canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
%           uLCD = obj.rig.getDevice('uLCD');
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(0);
            
            uStim=squirrellab.stimuli.uLCDMaskSpotGenerator();
            uStim.preTime=obj.preTime*1e-3;
            uStim.stimTime=obj.stimTime*1e-3;
            uStim.tailTime=obj.tailTime*1e-3;          
            uStim.spotRadius=obj.spotRadius;
            uStim.centerX=obj.currentX;
            uStim.centerY=obj.currentY;
            p.addStimulus(uStim);
            
            uLCDCMD = stage.builtin.controllers.PropertyController(uStim, 'cmdCount', @(state)squirrellab.stage2.uLCDGridSpotController(state));
            p.addController(uLCDCMD);
            
            center = stage.builtin.stimuli.Ellipse();
            center.color = 1;
            center.radiusX = obj.spotRadius;
            center.radiusY = obj.spotRadius;
            center.position = [uStim.centerX, uStim.centerY];
            p.addStimulus(center);        
            centerVisible = stage.builtin.controllers.PropertyController(center, 'visible',...
                @(state)state.time > uStim.preTime && state.time <= (uStim.preTime + uStim.stimTime));
            p.addController(centerVisible);  
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@io.github.stage_vss.protocols.StageProtocol(obj, epoch);
            
            device = obj.rig.getDevice(obj.amp);
            duration = (obj.preTime + obj.stimTime + obj.tailTime) / 1e3;
            epoch.addDirectCurrentStimulus(device, device.background, duration, obj.sampleRate);
            epoch.addResponse(device);
            epoch.addStimulus(obj.rig.getDevice(obj.led), obj.createLedStimulus());
            
            index = mod(obj.numEpochsCompleted, length(obj.sequenceX))+1;
            obj.currentX = obj.sequenceX(index);
            obj.currentY = obj.sequenceY(index);
            
            epoch.addParameter('currentX',obj.currentX);
            epoch.addParameter('currentY',obj.currentY);
            fprintf('nComp=%g, X=%g, Y=%g\n',obj.numEpochsPrepared,...
                obj.currentX,obj.currentY)
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@io.github.stage_vss.protocols.StageProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages*obj.nTotal;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages*obj.nTotal;
        end
        
    end
    
end

