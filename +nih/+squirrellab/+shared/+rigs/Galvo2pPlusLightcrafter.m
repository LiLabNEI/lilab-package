classdef Galvo2pPlusLightcrafter < nih.squirrellab.shared.rigs.Galvo2p
    
%     Galvo2pPlusStage - This rig description is identical to Galvo2p, but
%     includes a lightcrafter projector object so that communication with Stage can
%     take into account the LCR's unique properties.
%
%     Note that the Rieke lab lightcrafter device embeds a stage.client
%     instance that is used by Symphony, so there is no need to again add
%     Stage as a device here.
%     
%     Last modified 9-27-2018
    
    
    methods
        
        function obj = Galvo2pPlusLightcrafter()
            
            
            %MICRONSPERPIXEL and centerOffset calibrated on 4-5-2019 by JB
            %I plan to include a calibration protocol later.
            lightCrafter = nih.squirrellab.shared.devices.UVAmberLightCrafterDevice('micronsPerPixel', 0.3125);
            lightCrafter.setCenterOffset([0, 0])
            obj.addDevice(lightCrafter);            
            
            %As of now I haven't added any of the digital IO triggering
            %implemented by the Rieke lab
            
        end
        
    end
    
end
