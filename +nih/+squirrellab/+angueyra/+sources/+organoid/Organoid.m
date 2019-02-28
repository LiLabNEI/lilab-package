classdef Organoid < squirrellab.sources.Subject
    
    methods
        
        function obj = Organoid()
            import symphonyui.core.*;
            
            obj.addProperty('species', 'hiPSC', ...
                'type', PropertyType('char', 'row', {'hiPSC', 'H9','PEN8E',''}));

%             photoreceptors = containers.Map();
%             photoreceptors('SCone') = struct('collectingArea', 0.64, 'lambdaMax', 437);
% 			photoreceptors('MCone') = struct('collectingArea', 0.64, 'lambdaMax', 517);
%             photoreceptors('Rod')   = struct('collectingArea', 0.50, 'lambdaMax', 501);
%             obj.addResource('photoreceptors', photoreceptors);
            
            obj.addAllowableParentType([]);
        end
        
    end
    
    properties (Constant)

    end
    
end

