classdef ledConeTyping2P < squirrellab.protocols.SquirrelLabProtocol
    
     properties
        preTime = 100                   % Pulse leading duration (ms)
        stimTime = 10                   % Pulse duration (ms)
        tailTime = 390                  % Pulse trailing duration (ms)
        lLEDAmplitude = 5               % Pulse amplitude (V)
        sLEDAmplitude = 5               % Pulse amplitude (V)
        amp                             % Input amplifier
        numberOfAverages = uint16(2)    % Number of epochs
        interpulseInterval = 0          % Duration between pulses (s)
    end
    
    properties (Hidden)
        ledType
        ampType
        plotData
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@squirrellab.protocols.SquirrelLabProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end

        
        function prepareRun(obj)
            prepareRun@squirrellab.protocols.SquirrelLabProtocol(obj);
            
            obj.showFigure('symphonyui.builtin.figures.CustomFigure', @obj.updateFigure);
            obj.showFigure('squirrellab.figures.DataFigure', obj.rig.getDevice(obj.amp));
            obj.showFigure('squirrellab.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, ...
                'baselineRegion', [0 obj.preTime], ...
                'measurementRegion', [obj.preTime obj.preTime+obj.stimTime]);
        
            leds = obj.rig.getDevices('LED');
            for i = 1:numel(leds)
               leds{i}.background = symphonyui.core.Measurement(0, 'V');
            end
        end
        
        function updateFigure(obj, custFigObj, epoch)
            if obj.numEpochsCompleted == 1
                obj.plotData.figure = custFigObj.getFigureHandle();
                obj.initializeFigure(obj.plotData.figure);                
            end
            % get index of line to add to
            idx = mod(obj.numEpochsCompleted - 1, 2) + 1;
            % increment line's epoch counter
            obj.plotData.lines{idx}.UserData = ...
                obj.plotData.lines{idx}.UserData + 1;
            % update the line
            obj.plotData.lines{idx}.YData = ...
                obj.weightedAverage(obj.plotData.lines{idx}.YData, ...
                epoch.getResponse(obj.rig.getDevice(obj.amp)).getData(), ...
                obj.plotData.lines{idx}.UserData);
        end
        
        function ave = weightedAverage(obj, old, new, overallCount) %#ok<INUSL>
           oldFraction = (overallCount - 1) / overallCount;
           newFraction = 1 / overallCount;
           ave = (oldFraction * old) + (newFraction * new);
        end
        
        function initializeFigure(obj, figHand)
            set(figHand, 'Color', 'w');
            % make figure current
            % figure(figHand);
            % add axes
            obj.plotData.axes = axes(...
                'Parent', figHand, ...
                'NextPlot', 'add');
            
            
            % plot three lines of zero
            totPts = obj.getTotalPts();
            timePts = (1:totPts) / obj.sampleRate;
            obj.plotData.lines = cell(1,2);
            colors = [.5 0 0; 0 0 .75];
            for i = 1:2
               obj.plotData.lines{i} = plot(obj.plotData.axes, ...
                   timePts, zeros(1,totPts), ...
                   'Color', colors(i,:), ...
                   'LineWidth', 2); 
               obj.plotData.lines{i}.UserData = 0;
            end
        end
        
        function num = getTotalPts(obj)
            num = (obj.preTime + obj.stimTime + obj.tailTime) * ...
                obj.sampleRate / 1000;
        end
        
        function stim = createLedStimulus(obj,epochNum)
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.amplitude = obj.determineAmplitude(epochNum);
            gen.mean = 0;%obj.lightMean;
            gen.sampleRate = obj.sampleRate;
            gen.units = 'V';
            
            stim = gen.generate();
        end
        
        function amp = determineAmplitude(obj, epochNum)
           idx = mod(epochNum - 1, 2) + 1;
           if idx == 1
               amp = obj.lLEDAmplitude;
           elseif idx == 2
               amp  = obj.sLEDAmplitude;
           end
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@squirrellab.protocols.SquirrelLabProtocol(obj, epoch);
            
            % get epoch number
            epochNum = obj.numEpochsPrepared;
            
            epoch.addStimulus( ...
                obj.determineDevice(epochNum), ...
                obj.createLedStimulus(epochNum));
            epoch.addResponse(obj.rig.getDevice(obj.amp));
        end
        
        function device = determineDevice(obj, epochNum)
            idx = mod(epochNum - 1, 2) + 1;
            if idx == 1
                device = obj.rig.getDevice('mx405led');
            elseif idx == 2
                device = obj.rig.getDevice('mx590led');
            end
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@squirrellab.protocols.SquirrelLabProtocol(obj, interval);
            
%             device = obj.rig.getDevice(obj.led);
%             interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < (obj.numberOfAverages * 2);
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < (obj.numberOfAverages * 2);
        end

    end
    
end
