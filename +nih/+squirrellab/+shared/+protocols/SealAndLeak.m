classdef SealAndLeak < nih.squirrellab.shared.protocols.SquirrelLabProtocol
    % Presents a set of infinitely repeating rectangular pulse stimuli to a specified amplifier. This protocol records
    % and displays no responses. Instead it assumes you have an oscilloscope attached to your rig with which you can
    % view the amplifier response.
    
    properties
        amp                             % Output amplifier
        mode = 'seal'                   % Current mode of protocol
        alternateMode = true            % Alternate from seal to leak to seal etc., on each successive run
        preTime = 15                    % Pulse leading duration (ms)
        stimTime = 30                   % Pulse duration (ms)
        tailTime = 15                   % Pulse trailing duration (ms)
        pulseAmplitude = 5              % Pulse amplitude (mV or pA depending on amp mode)
        leakAmpHoldSignal = -60         % Amplifier hold signal to use while in leak mode (mV or pA depending on amp mode)
    end
    
    properties (Hidden, Dependent)
        ampHoldSignal                   % Amplifier hold signal (mV or pA depending on amp mode) 
    end
    
    properties (Dependent, SetAccess = private)
        amp2                            % Secondary amplifier
    end
    
    properties (Hidden)
        ampType
        modeType = symphonyui.core.PropertyType('char', 'row', {'seal', 'leak'})
        modeFigure
    end
    
    methods
        
        function s = get.ampHoldSignal(obj)
            if strcmpi(obj.mode, 'seal')
                s = 0;
            else
                s = obj.leakAmpHoldSignal;
            end
        end
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, name);
            
            if strncmp(name, 'amp2', 4) && numel(obj.rig.getDeviceNames('Amp')) < 2
                d.isHidden = true;
            end
        end
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()createPreviewStimuli(obj));
            function s = createPreviewStimuli(obj)
                gen = symphonyui.builtin.stimuli.PulseGenerator(obj.createAmpStimulus().parameters);
                s = gen.generate();
            end
        end
        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            if isempty(obj.modeFigure) || ~isvalid(obj.modeFigure)
                obj.modeFigure = obj.showFigure('symphonyui.builtin.figures.CustomFigure', @null);
                f = obj.modeFigure.getFigureHandle();
                set(f, 'Name', 'Mode');
                layout = uix.VBox('Parent', f);
                uix.Empty('Parent', layout);
                obj.modeFigure.userData.text = uicontrol( ...
                    'Parent', layout, ...
                    'Style', 'text', ...
                    'FontSize', 24, ...
                    'HorizontalAlignment', 'center', ...
                    'String', '');
                uix.Empty('Parent', layout);
                set(layout, 'Height', [-1 42 -1]);
            end
            
            if isvalid(obj.modeFigure)
                set(obj.modeFigure.userData.text, 'String', [obj.mode ' running...']);
            end
        end
        
        function stim = createAmpStimulus(obj)
            gen = symphonyui.builtin.stimuli.RepeatingPulseGenerator();
            
            gen.preTime = obj.preTime;
            gen.stimTime = obj.stimTime;
            gen.tailTime = obj.tailTime;
            gen.amplitude = obj.pulseAmplitude;
            gen.mean = obj.ampHoldSignal;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            stim = gen.generate();
        end
        
        function stim = createOscilloscopeTriggerStimulus(obj)
            gen = symphonyui.builtin.stimuli.RepeatingPulseGenerator();
            
            gen.preTime = 0;
            gen.stimTime = 1;
            gen.tailTime = obj.preTime + obj.stimTime + obj.tailTime - 1;
            gen.amplitude = 1;
            gen.mean = 0;
            gen.sampleRate = obj.sampleRate;
            gen.units = symphonyui.core.Measurement.UNITLESS;
            
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj, epoch);
            
            devices = obj.rig.getInputDevices();
            for i = 1:numel(devices)
                if epoch.hasResponse(devices{i})
                    epoch.removeResponse(devices{i});
                end
            end
            
            epoch.addStimulus(obj.rig.getDevice(obj.amp), obj.createAmpStimulus());
            
            triggers = obj.rig.getDevices('Oscilloscope Trigger');
            if ~isempty(triggers)            
                epoch.addStimulus(triggers{1}, obj.createOscilloscopeTriggerStimulus());
            end
            
            device = obj.rig.getDevice(obj.amp);
            device.background = symphonyui.core.Measurement(obj.ampHoldSignal, device.background.displayUnits);
        end
        
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < 1;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < 1;
        end
        
        function completeRun(obj)
            completeRun@nih.squirrellab.shared.protocols.SquirrelLabProtocol(obj);
            
            if obj.alternateMode
                if strcmpi(obj.mode, 'seal')
                    obj.mode = 'leak';
                else
                    obj.mode = 'seal';
                end
            end
            
            if isvalid(obj.modeFigure)
                set(obj.modeFigure.userData.text, 'String', [obj.mode ' next']);
            end
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

