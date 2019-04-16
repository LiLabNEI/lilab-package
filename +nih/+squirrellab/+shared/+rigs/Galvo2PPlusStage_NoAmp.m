classdef Galvo2PPlusStage_NoAmp < nih.squirrellab.shared.rigs.Galvo2p_NoAmp
    
%     Galvo2PPlusStage_NoAmp - This rig description is identical to Galvo2p_NoAmp, but
%     includes an instance of Stage as a device to talk to another instance
%     of Matlab running the Stage Server app
%     
%     Created 03-18-2019 (Angueyra)
%     Modified 03-18-2019 (Angueyra)
    
    
    methods
        
        function obj = Galvo2PPlusStage_NoAmp()
            
            %Add Stage to the rig definition.
            stage = io.github.stage_vss.devices.StageDevice('localhost');
            obj.addDevice(stage);
                        
        end
        
    end
    
end
