classdef RCFigure < symphonyui.core.FigureHandler
    % Dedicated figure to RC epochs that run at the start of every run
    
    properties
        userData
    end
    
    properties (SetAccess = private)
        handleEpochCallback
        clearCallback
    end
    
    methods
        
        function obj = RCFigure(handleEpochCallback, varargin)
            ip = inputParser();
            ip.addParameter('clearCallback', @(h)[], @(x)isa(x, 'function_handle'));
            ip.parse(varargin{:});
            
            obj.handleEpochCallback = handleEpochCallback;
            obj.clearCallback = ip.Results.clearCallback;
            
            set(obj.figureHandle, 'Name', 'RC Figure');
        end
        
        function h = getFigureHandle(obj)
            h = obj.figureHandle;
        end
        
        function clear(obj)
            obj.clearCallback(obj);
        end
        
        function handleEpoch(obj, epoch)
            obj.handleEpochCallback(obj, epoch);
        end
        
    end
        
end