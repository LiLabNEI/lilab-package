classdef MouseRetCell < squirrellab.sources.RetCell
    
    methods
        
        function obj = MouseRetCell()
            import symphonyui.core.*;
            obj.addAllowableParentType('squirrellab.sources.mouse.MouseRetPrep');
        end
        
    end
    
end

