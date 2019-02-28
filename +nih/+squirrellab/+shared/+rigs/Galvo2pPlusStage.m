classdef Galvo2pPlusStage < nih.squirrellab.shared.rigs.Galvo2p
    
%     Galvo2pPlusStage - This rig description is identical to Galvo2p, but
%     includes an instance of Stage as a device to talk to another instance
%     of Matlab running the Stage Server app
%     
%     Last modified 9-26-2018
    
    
    methods
        
        function obj = Galvo2pPlusStage()
            
            
            %These lines add Stage to the Galvo2p rig definition. As long as it is correctly
            %installed, nothing else needs to be done here.
            stage = io.github.stage_vss.devices.StageDevice('localhost');
            obj.addDevice(stage);
                        
            
        end
        
    end
    
end
