classdef Galvo2P_uLCD_OneAmp < nih.squirrellab.shared.rigs.Galvo2PPlusStage   

%     Galvo2P_uLCD_NoAmp - This rig description is identical to Galvo2PPlusStage, but
%     includes uLCD from 4D systems to be controlled through serial commands
%     
%     Created 03-18-2019 (Angueyra)
%     Modified 03-18-2019 (Angueyra)

   methods
        
        function obj = Galvo2P_uLCD_OneAmp()
            import symphonyui.builtin.devices.*;
            
			% need to check that this is the right port
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
