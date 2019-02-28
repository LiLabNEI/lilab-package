classdef (Abstract) SquirrelLabStageProtocol < io.github.stage_vss.protocols.StageProtocol & squirrellab.protocols.SquirrelLabProtocol
    
    methods (Abstract)
        p = createPresentation(obj);
    end
    
    methods
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@squirrellab.protocols.SquirrelLabProtocol(obj, epoch);
%             epoch.shouldWaitForTrigger = true; %external trigger start Symphony
            
%             % frame monitor from spatial stimulus for timing issues
%             frameMonitor = obj.rig.getDevices('Frame Monitor');
%             if ~isempty(frameMonitor)
%                 epoch.addResponse(frameMonitor{1});
%             end
        end
        
%         function pts = timeToPts (obj, t)
%             pts = round(t / 1e3 * obj.sampleRate);
%         end
    end
    
end

