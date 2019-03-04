classdef SqRetCell < nih.squirrellab.shared.sources.RetCell
    
    methods
        
        function obj = SqRetCell()
            import symphonyui.core.*;
            obj.addAllowableParentType('nih.squirrellab.shared.sources.squirrel.SqRetPrep');
        end
        
    end
    
end
