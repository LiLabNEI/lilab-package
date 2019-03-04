classdef MkRetPrep < nih.squirrellab.shared.sources.RetPrep
    
    methods
        
        function obj = MkRetPrep()
            import symphonyui.core.*;
            obj.addAllowableParentType('nih.squirrellab.shared.sources.monkey.Monkey');
        end
        
    end
    
end

