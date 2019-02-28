classdef ZFRetCell < squirrellab.sources.RetCell
    
    methods
        
        function obj = ZFRetCell()
            import symphonyui.core.*;
            obj.addAllowableParentType('squirrellab.sources.zebrafish.ZFRetPrep');
        end
        
    end
    
end
