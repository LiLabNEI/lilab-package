classdef Zebrafish < squirrellab.sources.Subject
    
    methods
        
        function obj = Zebrafish()
            import symphonyui.core.*;
            
            obj.addProperty('species', 'Danio rerio', ...
                'type', PropertyType('char', 'row', {'Danio rerio', ''}));
            obj.addProperty('strain background', {}, ...
                'type', PropertyType('cellstr', 'row', {'tab5', 'tub', 'tl'}), ... 
                'description', 'Strain background');
            obj.addProperty('genotype', {}, ...
                'type', PropertyType('cellstr', 'row', {'wt', 'eml1+/+', 'cpne3+/+'}), ... 
                'description', 'genotype');
            obj.addProperty('Stage', '', ...
                'type', PropertyType('char', 'row', {'2dpf', '3dpf', '4dpf', '5dpf', '6dpf', '7dpf', '8dpf', 'Adult', ''})...
                );
            obj.addProperty('Anesthesia', 'tricaine', ...
                'type', PropertyType('char', 'row', {'tricaine','bungarotoxin', ''})...
                );
            
            photoreceptors = containers.Map();
            photoreceptors('UVCone') = struct('collectingArea', NaN, 'lambdaMax', 365);
            photoreceptors('SCone') = struct('collectingArea', NaN, 'lambdaMax', 416);
			photoreceptors('MCone') = struct('collectingArea', 1.00, 'lambdaMax', 483);
            photoreceptors('LCone') = struct('collectingArea', NaN, 'lambdaMax', 574);
            photoreceptors('Rod')   = struct('collectingArea', NaN, 'lambdaMax', 501);
            obj.addResource('photoreceptors', photoreceptors);
            
            obj.addAllowableParentType([]);
        end
        
    end
    
    properties (Constant)

    end
    
end

