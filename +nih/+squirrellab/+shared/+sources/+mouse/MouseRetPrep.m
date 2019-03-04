classdef MouseRetPrep < nih.squirrellab.shared.sources.RetPrep
    
    methods
        
        function obj = MouseRetPrep()
            import symphonyui.core.*;
            obj.addAllowableParentType('nih.squirrellab.shared.sources.mouse.Mouse');
        end
        
    end
    
end

