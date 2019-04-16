classdef Galvo2pPlusLightcrafter_NoAmp < nih.squirrellab.shared.rigs.Galvo2p_NoAmp
    
%     Galvo2pPlusStage - This rig description is identical to Galvo2P_NoAmp, but
%     includes a lightcrafter projector object so that communication with Stage can
%     take into account the LCR's unique properties.
%
%     Note that the Rieke lab lightcrafter device embeds a stage.client
%     instance that is used by Symphony, so there is no need to again add
%     Stage as a device here.
%     
%     Last modified 9-27-2018
    
    
    methods
        
        function obj = Galvo2pPlusLightcrafter_NoAmp()
            
            %MICRONSPERPIXEL and centerOffset calibrated on 4-5-2019 by JB
            lightCrafter = nih.squirrellab.shared.devices.UVAmberLightCrafterDevice('micronsPerPixel', 0.3125);
            lightCrafter.setCenterOffset([0, 0])
            
            %Like with the filterWheel in the Galvo2p rig description, binding
            %the LCR so that its configuration properties are written to
            %each epoch
            daq = obj.daqController;
            lightCrafter.bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(lightCrafter, 15);
            
            obj.addDevice(lightCrafter);            
            
            
        end
        
    end
    
end
