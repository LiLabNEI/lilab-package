classdef MouseRetPrep < squirrellab.sources.RetPrep
    
    methods
        
        function obj = MouseRetPrep()
            import symphonyui.core.*;
            obj.addAllowableParentType('squirrellab.sources.mouse.Mouse');
        end
        
    end
    
end

