classdef RigA_OneAmpStage < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function obj = RigA_OneAmpStage()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaDaqController();
            obj.daqController = daq;
            
            amp1 = AxopatchDevice('Amp1').bindStream(daq.getStream('ao0'));
            amp1.bindStream(daq.getStream('ai0'), AxopatchDevice.SCALED_OUTPUT_STREAM_NAME);
            amp1.bindStream(daq.getStream('ai1'), AxopatchDevice.GAIN_TELEGRAPH_STREAM_NAME);
            %missing frequency input here (is that the low pass filter value?)
            amp1.bindStream(daq.getStream('ai2'), AxopatchDevice.MODE_TELEGRAPH_STREAM_NAME);
            obj.addDevice(amp1);
            
            led455 = UnitConvertingDevice('led455', 'V').bindStream(daq.getStream('ao3'));
%             led455.addConfigurationSetting('calvalue', '', ...
%                 'type', PropertyType('char', 'row', {'', 'low', 'medium', 'high'}));
            obj.addDevice(led455);
            
            led530 = UnitConvertingDevice('led530', 'V').bindStream(daq.getStream('ao2'));
            obj.addDevice(led530);
            
            led590 = UnitConvertingDevice('led591', 'V').bindStream(daq.getStream('ao1'));
            obj.addDevice(led590);
            
            T5Controller = UnitConvertingDevice('T5Controller', 'V','manufacturer','Bioptechs').bindStream(daq.getStream('ai6'));
            obj.addDevice(T5Controller);
            
            trigger = UnitConvertingDevice('Trigger', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(trigger, 0);
            obj.addDevice(trigger);
            
            stage = io.github.stage_vss.devices.StageDevice('localhost');
            obj.addDevice(stage);
        end
        
    end
    
end