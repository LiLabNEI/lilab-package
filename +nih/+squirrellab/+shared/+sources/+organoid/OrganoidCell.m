classdef OrganoidCell < nih.squirrellab.shared.sources.RetCell
    
    methods
        
        function obj = OrganoidCell()
            import symphonyui.core.*;
            obj.addAllowableParentType('nih.squirrellab.shared.sources.organoid.OrganoidPrep');
        end
        
    end
    
end
