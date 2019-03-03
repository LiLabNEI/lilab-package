classdef MkRetCell < squirrellab.sources.RetCell
    
    methods
        
        function obj = MkRetCell()
            import symphonyui.core.*;
            obj.addAllowableParentType('squirrellab.sources.monkey.MkRetPrep');
        end
        
    end
    
end