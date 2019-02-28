classdef RigA_OneAmpLCR < squirrellab.rigs.RigA_OneAmp
    
    methods
        
        function obj = RigA_OneAmpLCR()
            import symphonyui.builtin.devices.*;
            
            
            daq = obj.daqController;
            
            lightCrafter = squirrellab.devices.LightCrafterDevice('micronsPerPixel', 1.3);
            lightCrafter.bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(lightCrafter, 15);
            obj.addDevice(lightCrafter);

        end
        
    end
    
end

