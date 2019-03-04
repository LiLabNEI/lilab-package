classdef OrganoidPrep < nih.squirrellab.shared.sources.RetPrep
    
    methods
        
        function obj = OrganoidPrep()
            import symphonyui.core.*;
            obj.addAllowableParentType('nih.squirrellab.shared.sources.organoid.Organoid');
        end
        
    end
    
end

