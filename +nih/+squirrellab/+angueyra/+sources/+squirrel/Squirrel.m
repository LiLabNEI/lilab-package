classdef Squirrel < squirrellab.sources.Subject
    
    methods
        
        function obj = Squirrel()
            import symphonyui.core.*;
            
            obj.addProperty('species', 'Ictidomys tridicemlineatus', ...
                'type', PropertyType('char', 'row', {'Ictidomys tridicemlineatus', ''}));
            obj.addProperty('Status', 'Awake', ...
                'type', PropertyType('char', 'row', {'Awake', 'Hibernating', ''})...
                );
            obj.addProperty('LastHibernationStart', '', ...
                'type', PropertyType('char', 'row', 'datestr'), ...
                'description', 'Last time squirrel started hibernation cycle');
            obj.addProperty('LastHibernationEnd', '', ...
                'type', PropertyType('char', 'row', 'datestr'), ...
                'description', 'Last time squirrel awoke from hibernation cycle');
            
            photoreceptors = containers.Map();
            photoreceptors('SCone') = struct('collectingArea', 0.64, 'lambdaMax', 437);
			photoreceptors('MCone') = struct('collectingArea', 0.64, 'lambdaMax', 517);
            photoreceptors('Rod')   = struct('collectingArea', 0.50, 'lambdaMax', 501);
            obj.addResource('photoreceptors', photoreceptors);
            
            obj.addAllowableParentType([]);
        end
        
    end
    
    properties (Constant)

    end
    
end

