classdef Electrophysiology < symphonyui.core.persistent.descriptions.ExperimentDescription
    
    methods
        
        function obj = Electrophysiology()
            import symphonyui.core.*;
            
            obj.addProperty('experimenter', '', ...
                'description', 'Who performed the experiment');
            obj.addProperty('project', '', ...
                'description', 'Project the experiment belongs to');
            obj.addProperty('institution', 'NEI', ...
                'description', 'Institution where the experiment was performed');
            obj.addProperty('lab', 'LiLab', ...
                'description', 'Lab where experiment was performed');
        end
        
    end
    
end

