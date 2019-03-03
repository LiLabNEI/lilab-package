classdef OrganoidCell < squirrellab.sources.RetCell
    
    methods
        
        function obj = OrganoidCell()
            import symphonyui.core.*;
            obj.addAllowableParentType('squirrellab.sources.organoid.OrganoidPrep');
        end
        
    end
    
end