classdef vPulseFamily < squirrellab.protocols.SquirrelLabAutoRCProtocol %squirrellab.protocols.SquirrelLabAutoRCNoiseSineProtocol
    
    properties
        amp                             % Output amplifier
        preTime = 100                   % Pulse leading duration (ms)
        stimTime = 500                  % Pulse duration (ms)
        tailTime = 1500                 % Pulse trailing duration (ms)
        firstPulseSignal = -60          % First pulse signal value (mV or pA)
        incrementPerPulse = 10          % Increment value per each pulse (mV or pA)
        leakSub = true                  % Attempt leak subtraction with 5mV pulses
        leakN = uint16(2)               % Number of pairs of low voltage stimuli to run for leak subtraction
        pulsesInFamily = uint16(15)     % Number of pulses in family
        numberOfAverages = uint16(1)    % Number of families
        interpulseInterval = 0          % Duration between pulses (s)
    end
    
    properties (Hidden)
        ampType
        nPulses
        plotData
    end
    
    methods
        
        function didSetRig(obj)
%             didSetRig@squirrellab.protocols.SquirrelLabAutoRCNoiseSineProtocol(obj);
            didSetRig@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj);
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()createPreviewStimuli(obj));
            function s = createPreviewStimuli(obj)
                [nPulses, ~] = obj.leakParsing; %#ok<*PROPLC>
                s = cell(1, nPulses);
                for i = 1:numel(s)
                    s{i} = obj.createAmpStimulus(i);
                end
            end
        end
        
        function prepareRun(obj)           
            prepareRun@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj);
            
            [obj.nPulses, pulseAmp] = obj.leakParsing;
            
            % Data Figure
            obj.showFigure('squirrellab.figures.DataFigure', obj.rig.getDevice(obj.amp));
            % Mean Figure + IV
            obj.showFigure('squirrellab.figures.vPulseFamilyIVFigure', obj.rig.getDevice(obj.amp), ...
                'prepts',obj.timeToPts(obj.preTime),...
                'stmpts',obj.timeToPts(obj.stimTime),...
                'nPulses',double(obj.nPulses),...
                'pulseAmp',pulseAmp+obj.rig.getDevice(obj.amp).background.quantity,...
                'groupBy', {'pulseSignal'});
            %Baseline and StD tracking
            obj.showFigure('squirrellab.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @std}, ...
                'baselineRegion', [0 obj.preTime], ...
                'measurementRegion', [obj.preTime obj.preTime+obj.stimTime]);
            obj.showFigure('squirrellab.figures.ProgressFigure', obj.numberOfAverages * obj.nPulses);
        end
        
        function [stim, pulseSignal] = createAmpStimulus(obj, pulseNum)
            
            [~, pulseAmp] = obj.leakParsing;
            pulseSignal = pulseAmp(pulseNum);
            
            gen = symphonyui.builtin.stimuli.PulseGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.mean = obj.rig.getDevice(obj.amp).background.quantity;
            gen.amplitude = pulseSignal;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj, epoch);
            if obj.runRC
                % Superclass runs RC epoch
            else %run normally
                [nPulses, ~] = obj.leakParsing;
                
                pulseNum = mod(obj.numEpochsPrepared - 1, nPulses) + 1;
                [stim, pulseSignal] = obj.createAmpStimulus(pulseNum);
                
                epoch.addParameter('pulseSignal', pulseSignal+obj.rig.getDevice(obj.amp).background.quantity);
                epoch.addStimulus(obj.rig.getDevice(obj.amp), stim);
                epoch.addResponse(obj.rig.getDevice(obj.amp));
            end
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@squirrellab.protocols.SquirrelLabAutoRCProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages * obj.nPulses;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages * obj.nPulses;
        end
        
        function [nPulses, pulseAmp] = leakParsing(obj)    
            if obj.leakSub
                leakPulses = repmat([-5 5],1,obj.leakN);
                nLeakPulses = size(leakPulses,2);
            else
                leakPulses = [];
                nLeakPulses = 0;
            end
            nPulses = obj.pulsesInFamily + nLeakPulses;
            pulseAmp = [leakPulses ((0:double(obj.pulsesInFamily)-1) * obj.incrementPerPulse) + obj.firstPulseSignal]; 
        end
    end
    
end

