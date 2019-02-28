classdef RigA_OneAmpUlcd < squirrellab.rigs.RigA_OneAmpStage
       
    methods
        
        function obj = RigA_OneAmpUlcd()
            import symphonyui.builtin.devices.*;
            
            uLCD = squirrellab.devices.uLCDDevice('comPort','COM9');
%             uLCD.serial.connect();           
%             fprintf('Initialized uLCD\n')
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
    
