classdef vRamp < nih.squirrellab.shared.protocols.SquirrelLabAutoRCProtocol 
    
    properties
        amp                             % Output amplifier
        preTime = 50                    % Ramp leading duration (ms)
        stimTime = 500                  % Ramp duration (ms)
        tailTime = 1500                   % Ramp trailing duration (ms)
        rampStart = -120                % Ramp amplitude (mV or pA)
        rampEnd = 50                    % Ramp amplitude (mV or pA)
    end
   
    properties (Dependent, SetAccess = private)
        amp2                            % Secondary amplifier
    end
	
    properties
        numberOfAverages = uint16(3)    % Number of epochs
        interpulseInterval = 0.2          % Duration between ramps (s)
    end
    
    properties (Hidden)
        ampType
        plotData
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.SquirrelLabAutoRCProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end
		
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, name);
        
            if strncmp(name, 'amp2', 4) && numel(obj.rig.getDeviceNames('Amp')) < 2
                d.isHidden = true;
            end
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()obj.createAmpStimulus());
        end
        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.SquirrelLabAutoRCProtocol(obj);
	       
			if numel(obj.rig.getDeviceNames('Amp')) < 2
	            obj.showFigure('nih.squirrellab.shared.figures.DataFigure', obj.rig.getDevice(obj.amp));
	            obj.showFigure('nih.squirrellab.shared.figures.AverageFigure', obj.rig.getDevice(obj.amp));
	            obj.showFigure('nih.squirrellab.shared.figures.ResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @std}, ...
	                'baselineRegion', [0 obj.preTime], ...
	                'measurementRegion', [0 obj.preTime]);
			else
                obj.showFigure('nih.squirrellab.shared.figures.DualResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2));
                obj.showFigure('nih.squirrellab.shared.figures.DualMeanResponseFigure', obj.rig.getDevice(obj.amp), obj.rig.getDevice(obj.amp2));
                obj.showFigure('nih.squirrellab.shared.figures.DualResponseStatisticsFigure', obj.rig.getDevice(obj.amp), {@mean, @var}, obj.rig.getDevice(obj.amp2), {@mean, @var}, ...
                    'baselineRegion1', [0 obj.preTime], ...
                    'measurementRegion1', [obj.preTime obj.preTime+obj.stimTime], ...
                    'baselineRegion2', [0 obj.preTime], ...
                    'measurementRegion2', [obj.preTime obj.preTime+obj.stimTime]);
			end
				
            obj.showFigure('nih.squirrellab.shared.figures.ProgressFigure', obj.numberOfAverages);
        end
        
        function stim = createAmpStimulus(obj)
            g1 = symphonyui.builtin.stimuli.RampGenerator();
            
            g1.preTime = obj.preTime;
            g1.stimTime = obj.stimTime;
            g1.tailTime = obj.tailTime;
            g1.amplitude = obj.rampEnd-obj.rampStart;
            g1.mean = obj.rampStart;
            g1.sampleRate = obj.sampleRate;
            g1.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            ramp = g1.generate();
                       
            g2 = symphonyui.builtin.stimuli.PulseGenerator();
            
            g2.preTime = 0;
            g2.stimTime = obj.preTime;
            g2.tailTime = obj.stimTime + obj.tailTime;
            g2.amplitude = obj.rig.getDevice(obj.amp).background.quantity-obj.rampStart;
            g2.mean = 0;
            g2.sampleRate = obj.sampleRate;
            g2.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            pulse1=g2.generate();
            
            g3 = symphonyui.builtin.stimuli.PulseGenerator();
            
            g3.preTime = obj.preTime + obj.stimTime;
            g3.stimTime = obj.tailTime;
            g3.tailTime = 0;
            g3.amplitude = obj.rig.getDevice(obj.amp).background.quantity-obj.rampStart;
            g3.mean = 0;
            g3.sampleRate = obj.sampleRate;
            g3.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            pulse2=g3.generate();

            
            g=symphonyui.builtin.stimuli.SumGenerator();
            g.stimuli={ramp,pulse1,pulse2};
            
            stim=g.generate;
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.SquirrelLabAutoRCProtocol(obj, epoch);
            if obj.runRC
                % Superclass runs RC epoch
            else %run normally
                epoch.addStimulus(obj.rig.getDevice(obj.amp), obj.createAmpStimulus());
                epoch.addResponse(obj.rig.getDevice(obj.amp));
				
	            if numel(obj.rig.getDeviceNames('Amp')) >= 2
	                epoch.addResponse(obj.rig.getDevice(obj.amp2));
	            end
					
            end
        end
        
        function prepareInterval(obj, interval)
            prepareInterval@nih.squirrellab.shared.protocols.SquirrelLabAutoRCProtocol(obj, interval);
            
            device = obj.rig.getDevice(obj.amp);
            interval.addDirectCurrentStimulus(device, device.background, obj.interpulseInterval, obj.sampleRate);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
			
        function a = get.amp2(obj)
            amps = obj.rig.getDeviceNames('Amp');
            if numel(amps) < 2
                a = '(None)';
            else
                i = find(~ismember(amps, obj.amp), 1);
                a = amps{i};
            end
        end
				
    end
    
end
				
				

