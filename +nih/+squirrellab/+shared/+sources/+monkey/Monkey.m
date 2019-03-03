classdef Monkey < squirrellab.sources.Subject
    
    methods
        
        function obj = Monkey()
            import symphonyui.core.*;
            
            obj.addProperty('species', 'M. mulatta', ...
                'type', PropertyType('char', 'row', {'M. mulatta', 'M. fascicularis', 'M. nemestrina', ''}));
            obj.addProperty('Status', '', ...
                'type', PropertyType('char', 'row', {'Normal', 'Sick', 'Psycho', ''})...
                );
            
            photoreceptors = containers.Map();
            photoreceptors('SCone') = struct('collectingArea', 0.64, 'lambdaMax', 420);
			photoreceptors('MCone') = struct('collectingArea', 0.64, 'lambdaMax', 534);
            photoreceptors('LCone') = struct('collectingArea', 0.64, 'lambdaMax', 564);
            photoreceptors('Rod')   = struct('collectingArea', 0.50, 'lambdaMax', 498);
            obj.addResource('photoreceptors', photoreceptors);
            
            
%              photoreceptors = containers.Map();
%             photoreceptors('lCone') = struct( ...
%                 'collectingArea', containers.Map({'photoreceptorSide', 'ganglionCellSide'}, {0.37, 0.60}), ...
%                 'spectrum', importdata(squirrellab.Package.getCalibrationResource('sources', 'primate', 'l_cone_spectrum.txt')));
%             photoreceptors('mCone') = struct( ...
%                 'collectingArea', containers.Map({'photoreceptorSide', 'ganglionCellSide'}, {0.37, 0.60}), ...
%                 'spectrum', importdata(squirrellab.Package.getCalibrationResource('sources', 'primate', 'm_cone_spectrum.txt')));
%             photoreceptors('rod') = struct( ...
%                 'collectingArea', containers.Map({'photoreceptorSide', 'ganglionCellSide'}, {1.00, 1.00}), ...
%                 'spectrum', importdata(squirrellab.Package.getCalibrationResource('sources', 'primate', 'rod_spectrum.txt')));
%             photoreceptors('sCone') = struct( ...
%                 'collectingArea', containers.Map({'photoreceptorSide', 'ganglionCellSide'}, {0.37, 0.60}), ...
%                 'spectrum', importdata(squirrellab.Package.getCalibrationResource('sources', 'primate', 's_cone_spectrum.txt')));
%             obj.addResource('photoreceptors', photoreceptors);
%             
            
            
            obj.addAllowableParentType([]);
        end
        
    end
    
    properties (Constant)

    end
    
end

