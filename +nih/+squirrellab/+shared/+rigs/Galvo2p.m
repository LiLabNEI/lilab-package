classdef Galvo2p < symphonyui.core.descriptions.RigDescription
    
%     Galvo2P - This rig description intializes the following rig
%     configuration:
%     
%     Digital acquisition board: Heka ITC-18
%     Amplifier:  A single Axopatch 200B 
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
%             scaled output --> analog input 0
%             gain telegraph --> analog input 1
%             voltage/current clamp mode --> analog input 3
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
%     This rig configuration has been modified by John Ball from Juan Angueyra's
%     rig configuration file.
%     
%     Last modified 9-26-2018
    
    
    
    
    methods
        
        function obj = Galvo2p()
            
            %These lines put us on a first-name basis with the object
            %definitions found in these package folders (rather than having
            %to type out the whole path each time)
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            
            %Adds Heka ITC-18 as DAQ card.
            daq = HekaDaqController();  %defined in symphonyui.builtin.daqs
            obj.daqController = daq;
            
            
            
            %ITC ports are numbered from zero, not 1. So, ao0 = First Analog Output, ai2 = Third Analog Input, etc.
            
            %Adds Axopatch 200B to rig and then binds analog output 0
            %(i.e., ao0) to the amplifier object we create
            amp1 = AxopatchDevice('Amp1').bindStream(daq.getStream('ao0'));  %defined in symphonyui.builtin.devices
            
            %Tells Symphony to bind the ITC18 analog input 0 to the scaled output as
            %defined in the AxopatchDevice object file
            amp1.bindStream(daq.getStream('ai0'), AxopatchDevice.SCALED_OUTPUT_STREAM_NAME);
            
            %Same thing, but now tell symphony to associate ITC18 analog
            %input 1 with the gain telegraph from the amplifier
            amp1.bindStream(daq.getStream('ai1'), AxopatchDevice.GAIN_TELEGRAPH_STREAM_NAME);
            
            %missing frequency input here (is that the low pass filter value?)
            
            %Now look for the amplifier mode to be telegraphed over analog
            %input 3
            amp1.bindStream(daq.getStream('ai3'), AxopatchDevice.MODE_TELEGRAPH_STREAM_NAME);
            obj.addDevice(amp1);
            
            %If possible it might be best to add configuration settings to
            %the amp to cover the other settings that don't get
            %telegraphed from the amplifier itself
            
            %This initializes a digital input called "frame monitor" that
            %is associated with the first channel on the digital input
            %port. As of right now it's not being used but it will be
            %useful to monitor frame flips for the visual stimulus
            frame = UnitConvertingDevice('FrameMonitor', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('diport0'));
            daq.getStream('diport0').setBitPosition(frame, 0);
            obj.addDevice(frame);

            
            %Initializing the UV LED on analog output 2 (the third analog output)
            mx405LED = UnitConvertingDevice('UV LED 405nm', 'V','manufacturer','Mightex').bindStream(daq.getStream('ao2'));
            
            %I commented out both NDF configuration lines because no NDFs
            %are being used on this system. Obvs can update later if we
            %start using them
            
%             mx405LED.addConfigurationSetting('ndfs', {}, ...
%                 'type', PropertyType('cellstr', 'row', {'0.3', '0.6', '1.2', '3.0', '4.0'}));

            %Configuration settings like this mean nothing for the actual
            %LED; they're only used to keep records of what you use (but
            %you have to select the configuration settings yourself during the
            %experiment)
            mx405LED.addConfigurationSetting('Imax', '350 mA', ...
                'type', PropertyType('char', 'row', {'350 mA', '500 mA', '1000 mA'}));
            obj.addDevice(mx405LED);
            
            
            %Initializing the Amber LED on analog output 3 (the fourth analog output)
            mx590LED = UnitConvertingDevice('Amber LED 590nm', 'V','manufacturer','Mightex').bindStream(daq.getStream('ao3'));
%             mx590LED.addConfigurationSetting('ndfs', {}, ...
%                 'type', PropertyType('cellstr', 'row', {'0.3', '0.6', '1.2', '3.0', '4.0'}));

            mx590LED.addConfigurationSetting('Imax', '350 mA', ...
                'type', PropertyType('char', 'row', {'350 mA', '500 mA', '1000 mA'}));
            obj.addDevice(mx590LED);
            
            
            %This adds a device on analog input 7 that is intended to read
            %the temperature of the dish from the Bioptechs temperature
            %controller. In practice Juan only reads it once per protocol,
            %which I think makes sense
            T5Controller = UnitConvertingDevice('T5Controller', 'V','manufacturer','Bioptechs').bindStream(daq.getStream('ai7'));
            obj.addDevice(T5Controller);

            
            %This is a generic digital output (on digital output channel 1--the second channel) used to trigger other
            %devices. 
            sciscanTrigger = UnitConvertingDevice('SciScan trigger', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(sciscanTrigger, 0);
            obj.addDevice(sciscanTrigger);
            
            
            %I took the filter wheel device & related module files from the
            %Rieke Lab package on github. (sorry)
            %Adds the thorlab filter wheel device to this system (it was on COM11
            %when I checked)
            filterWheel = nih.squirrellab.shared.devices.RiekeFilterWheelDevice('comPort', 'COM11');
            
            
            %Per original file: Binding the filter wheel to an unused stream only so its configuration settings are written to each epoch.
            daq = obj.daqController;
            filterWheel.bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(filterWheel, 15);
            
            obj.addDevice(filterWheel);
            
        end
        
    end
    
end
