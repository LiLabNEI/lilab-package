classdef ModelCell < squirrellab.sources.Cell
    
    methods
        
        function obj = ModelCell()
            import symphonyui.core.*;
            
           obj.addProperty('model', 'PATCH-1U', ...
                'type', PropertyType('char', 'row', {'', 'PATCH-1U'}), ...
                'description', 'model of the model cell');
            obj.addProperty('mode', 'CELL', ...
                'type', PropertyType('char', 'row', {'', 'BATH', 'PATCH', 'CELL'}), ...
                'description', 'mode in use');
            obj.addAllowableParentType([]);
        end
        
    end
    
end