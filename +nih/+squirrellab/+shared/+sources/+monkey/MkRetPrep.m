classdef MkRetPrep < squirrellab.sources.RetPrep
    
    methods
        
        function obj = MkRetPrep()
            import symphonyui.core.*;
            obj.addAllowableParentType('squirrellab.sources.monkey.Monkey');
        end
        
    end
    
end

