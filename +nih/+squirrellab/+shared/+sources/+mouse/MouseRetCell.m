classdef MouseRetCell < nih.squirrellab.shared.sources.RetCell
    
    methods
        
        function obj = MouseRetCell()
            import symphonyui.core.*;
            obj.addAllowableParentType('nih.squirrellab.shared.sources.mouse.MouseRetPrep');
        end
        
    end
    
end

