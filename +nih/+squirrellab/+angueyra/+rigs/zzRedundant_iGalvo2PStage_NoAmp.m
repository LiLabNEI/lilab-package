classdef iGalvo2PStage_NoAmp < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function obj = iGalvo2PStage_NoAmp()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaDaqController();
            obj.daqController = daq;

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
