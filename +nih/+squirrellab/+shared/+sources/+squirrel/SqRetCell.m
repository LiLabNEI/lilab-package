classdef SqRetCell < squirrellab.sources.RetCell
    
    methods
        
        function obj = SqRetCell()
            import symphonyui.core.*;
            obj.addAllowableParentType('squirrellab.sources.squirrel.SqRetPrep');
        end
        
    end
    
end