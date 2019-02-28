classdef iElectrophysiology < symphonyui.core.persistent.descriptions.ExperimentDescription
    % Two Photon imaging combined with electrophsyiology tools and
    % management.
    methods
        
        function obj = iElectrophysiology()
            import symphonyui.core.*;
            
            obj.addProperty('experimenter', 'Juan', ...
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

