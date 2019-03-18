classdef Galvo2p < symphonyui.core.descriptions.RigDescription
    
%     Galvo2P - This rig description intializes the following rig
%     configuration:
%     
%     Digital acquisition board: Heka ITC-18
%     Amplifier:  NONE
%     Mightex UV LED (405 nm)
%     Mightex Amber LED (509 nm)
%     Bioptechs temperature controller temp monitor
%     Thorlabs motorized NDF filter wheel
%     One each of a digital output trigger and input frame monitor
%     
%     These devices are configured as follows:
%             command signal --> analog output 0
%             UV LED control voltage --> analog output 2
%             Amber LED control voltage --> analog output 3
%             
%             temperature monitor --> analog input 7
%             
%             frame monitor --> digital input 0 pin 0
%             digital trigger --> digital output 1 pin 0
%             filter wheel --> digital output 1 pin 15 (only to trick symphony
%               into storing status info for the filter wheel)
%                 
%     Each LED has an Imax configuration for 350, 500, or 1000 mA that
%     should correspond to front dip pin states of 00, 10, and 11, respectively.
%
%     This rig configuration is a duplication of Galvo2P, but just omits initializing the amplifier
%     
%     Last modified 03-18-2019 (Angueyra)
    
    
    
    
    methods
        
        function obj = Galvo2p()
            
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            
            %Adds Heka ITC-18 as DAQ card.
            daq = HekaDaqController();  %defined in symphonyui.builtin.daqs
            obj.daqController = daq;
             
            %Initializes a digital input to monitor imaging frame flips
            frame = UnitConvertingDevice('FrameMonitor', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('diport0'));
            daq.getStream('diport0').setBitPosition(frame, 0);
            obj.addDevice(frame);

            %Initializing the UV LED on analog output 2 (the third analog output)
            mx405LED = UnitConvertingDevice('UV LED 405nm', 'V','manufacturer','Mightex').bindStream(daq.getStream('ao2'));
            
            %Configuration settings like this mean nothing for the actual
            %LED; they're only used to keep records of what you use (but
            %you have to select the configuration settings yourself during the
            %experiment)
            mx405LED.addConfigurationSetting('Imax', '350 mA', ...
                'type', PropertyType('char', 'row', {'350 mA', '500 mA', '1000 mA'}));
            obj.addDevice(mx405LED);
            
			%Adding option for NDFs used in turret (clear 3D printed holders)            
            mx405LED.addConfigurationSetting('ndfs', {}, ...
                'type', PropertyType('cellstr', 'row', {'0.5', '2'}));
            %Adding option for dichroic used to block green light
            mx405LED.addConfigurationSetting('filters', {}, ...
                'type', PropertyType('cellstr', 'row', {'none', 'dichroicBriggman'}));
			
            
            %Initializing the Amber LED on analog output 3 (the fourth analog output)
            mx590LED = UnitConvertingDevice('Amber LED 590nm', 'V','manufacturer','Mightex').bindStream(daq.getStream('ao3'));
            
            %Configuration settings like this mean nothing for the actual
            %LED; they're only used to keep records of what you use (but
            %you have to select the configuration settings yourself during the
            %experiment)
            mx590LED.addConfigurationSetting('Imax', '350 mA', ...
                'type', PropertyType('char', 'row', {'350 mA', '500 mA', '1000 mA'}));
            obj.addDevice(mx590LED);
			
			%Adding option for NDFs used in turret (clear 3D printed holders)            
            mx590LED.addConfigurationSetting('ndfs', {}, ...
                'type', PropertyType('cellstr', 'row', {'0.5', '2'}));
            %Adding option for dichroic used to block green light
            mx590LED.addConfigurationSetting('filters', {}, ...
                'type', PropertyType('cellstr', 'row', {'none', 'dichroicBriggman'}));

            
            %Adds a device on analog input 7 that is intended to read
            %the temperature of the dish from the Bioptechs temperature
            %controller. This is sampled at same rate as ampflifiers, but Juan's
			% protocols average over each epoch and replace the data witha single measurement
            T5Controller = UnitConvertingDevice('T5Controller', 'V','manufacturer','Bioptechs').bindStream(daq.getStream('ai7'));
            obj.addDevice(T5Controller);

            
            %This is a generic digital output (on digital output channel 1--the second channel) used to trigger other
            %devices. In present configuration, all "i" Protocols send a trigger at the beginning of run to trigger imaging form SciScan.
			%This requires enabling trigger in SciScan and starting "RECORD"
            sciscanTrigger = UnitConvertingDevice('SciScan trigger', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(sciscanTrigger, 0);
            obj.addDevice(sciscanTrigger);
            
            
            %Filter wheel device & related module adapted from the
            %Rieke Lab package on github. (https://github.com/Rieke-Lab/riekelab-package)
            %Adds the thorlab filter wheel device to this system (currently COM1)
            filterWheel = nih.squirrellab.shared.devices.RiekeFilterWheelDevice('comPort', 'COM11');
            
            
            %Per original file: Binding the filter wheel to an unused stream only so its configuration settings are written to each epoch.
			%As with temperature controller, data from filterWheel will be sampled at same rate as amplifiers.
			%Protocols could be set up to foollow temperature controller and replace data with single measurement for each epoch (but not set up yet).
            daq = obj.daqController;
            filterWheel.bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(filterWheel, 15);
            
            obj.addDevice(filterWheel);
            
        end
        
    end
    
end
