classdef iGalvo2PStage_OneAmp < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function obj = iGalvo2PStage_OneAmp()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaDaqController();
            obj.daqController = daq;
            
            amp1 = AxopatchDevice('Amp1').bindStream(daq.getStream('ao0'));
            amp1.bindStream(daq.getStream('ai0'), AxopatchDevice.SCALED_OUTPUT_STREAM_NAME);
            amp1.bindStream(daq.getStream('ai1'), AxopatchDevice.GAIN_TELEGRAPH_STREAM_NAME);
            %missing frequency input here (is that the low pass filter value?)
            amp1.bindStream(daq.getStream('ai3'), AxopatchDevice.MODE_TELEGRAPH_STREAM_NAME);
            obj.addDevice(amp1);
            
            frame = UnitConvertingDevice('FrameMonitor', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('diport0'));
            daq.getStream('diport0').setBitPosition(frame, 0);
            obj.addDevice(frame);

            mx405LED = UnitConvertingDevice('mx405LED', 'V','manufacturer','Mightex').bindStream(daq.getStream('ao2'));
            mx405LED.addConfigurationSetting('ndfs', {}, ...
                'type', PropertyType('cellstr', 'row', {'0.3', '0.6', '1.2', '3.0', '4.0'}));
            mx405LED.addConfigurationSetting('gain', '', ...
                'type', PropertyType('char', 'row', {'', 'low', 'medium', 'high'}));
            obj.addDevice(mx405LED);
            
            mx590LED = UnitConvertingDevice('mx590LED', 'V','manufacturer','Mightex').bindStream(daq.getStream('ao3'));
            mx590LED.addConfigurationSetting('ndfs', {}, ...
                'type', PropertyType('cellstr', 'row', {'0.3', '0.6', '1.2', '3.0', '4.0'}));
            mx590LED.addConfigurationSetting('gain', '', ...
                'type', PropertyType('char', 'row', {'', 'low', 'medium', 'high'}));
            obj.addDevice(mx590LED);
            
            T5Controller = UnitConvertingDevice('T5Controller', 'V','manufacturer','Bioptechs').bindStream(daq.getStream('ai7'));
            obj.addDevice(T5Controller);

            trigger = UnitConvertingDevice('Trigger', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(trigger, 0);
            obj.addDevice(trigger);
            
            stage = io.github.stage_vss.devices.StageDevice('localhost');
            obj.addDevice(stage);
        end
        
    end
    
end
