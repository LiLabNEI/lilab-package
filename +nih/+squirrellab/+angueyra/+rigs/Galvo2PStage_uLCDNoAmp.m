classdef Galvo2PStage_uLCDNoAmp < nih.squirrellab.angueyra.rigs.iGalvo2PStage_NoAmp   
 
   methods
        
        function obj = Galvo2PStage_uLCDNoAmp()
            import symphonyui.builtin.devices.*;
            
            uLCD = squirrellab.devices.uLCDDevice('comPort','COM9');
            uLCD.serial.connect();           
            fprintf('Initialized uLCD\n')
            % Binding the uLCD to an unused stream only so its configuration settings are written to each epoch.
            daq = obj.daqController;
            uLCD.bindStream(daq.getStream('doport0'));
            daq.getStream('doport0').setBitPosition(uLCD, 0);
            fprintf('uLCD is bound to DAQ\n')
            obj.addDevice(uLCD);
            fprintf('uLCD has been added as device\n')
        end
        
    end
end