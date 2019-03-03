classdef OrganoidPrep < squirrellab.sources.RetPrep
    
    methods
        
        function obj = OrganoidPrep()
            import symphonyui.core.*;
            obj.addAllowableParentType('squirrellab.sources.organoid.Organoid');
        end
        
    end
    
end

