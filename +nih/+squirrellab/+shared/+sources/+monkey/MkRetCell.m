classdef MkRetCell < nih.squirrellab.shared.sources.RetCell
    
    methods
        
        function obj = MkRetCell()
            import symphonyui.core.*;
            obj.addAllowableParentType('nih.squirrellab.shared.sources.monkey.MkRetPrep');
        end
        
    end
    
end
