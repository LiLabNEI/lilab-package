classdef ZFRetCell < nih.squirrellab.shared.sources.RetCell
    
    methods
        
        function obj = ZFRetCell()
            import symphonyui.core.*;
            obj.addAllowableParentType('nih.squirrellab.shared.sources.zebrafish.ZFRetPrep');
        end
        
    end
    
end
