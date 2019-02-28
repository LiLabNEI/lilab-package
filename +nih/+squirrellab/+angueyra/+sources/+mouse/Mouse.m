classdef Mouse < squirrellab.sources.Subject
    
    methods
        
        function obj = Mouse()
            import symphonyui.core.*;
            
            obj.addProperty('genotype', {}, ...
                'type', PropertyType('cellstr', 'row', {'C57B6', 'WT', 'OPN1MW-Cre', 'Cx36-/-', 'EML1+/-', 'EML1-/-'}), ... 
                'description', 'Genetic strain');
            
            photoreceptors = containers.Map();
            photoreceptors('SCone') = struct('collectingArea', 0.20, 'lambdaMax', 360);
			photoreceptors('MCone') = struct('collectingArea', 0.20, 'lambdaMax', 508);
            photoreceptors('Rod')   = struct('collectingArea', 0.50, 'lambdaMax', 498);
            obj.addResource('photoreceptors', photoreceptors);
            
            obj.addAllowableParentType([]);
        end
        
    end
    
    properties (Constant)

    end
    
end

