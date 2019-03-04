classdef SqRetPrep < nih.squirrellab.shared.sources.RetPrep
    
    methods
        
        function obj = SqRetPrep()
            import symphonyui.core.*;
            obj.addAllowableParentType('nih.squirrellab.shared.sources.squirrel.Squirrel');
        end
        
    end
    
end

