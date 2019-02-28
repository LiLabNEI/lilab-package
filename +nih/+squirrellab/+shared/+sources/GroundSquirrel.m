classdef GroundSquirrel < symphonyui.core.persistent.descriptions.SourceDescription
    
    methods
        
        function obj = GroundSquirrel()
            obj.addProperty('ID', uint32(0), 'type', symphonyui.core.PropertyType('uint32', 'scalar'));
            obj.addProperty('Sex', '', 'type', symphonyui.core.PropertyType('char', 'row', {'', 'male', 'female'}));
            obj.addProperty('Birth date', datestr(now), 'type', symphonyui.core.PropertyType('char', 'row', 'datestr'));
            obj.addProperty('Hibernation state', '', 'type', symphonyui.core.PropertyType('char', 'row', {'', 'awake', 'hibernating'}),'description','Activity/hibernation state of the animal at the time it was sacrificed');
            
            obj.addAllowableParentType([]);
        end

    end
    
end

