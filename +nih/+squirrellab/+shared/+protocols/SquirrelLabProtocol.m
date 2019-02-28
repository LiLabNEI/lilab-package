classdef (Abstract) SquirrelLabProtocol < symphonyui.core.Protocol
    
    methods
        function prepareEpoch(obj, epoch)
            prepareEpoch@symphonyui.core.Protocol(obj, epoch);
            % add remperature controller monitor
            T5Controller = obj.rig.getDevices('T5Controller');
            if ~isempty(T5Controller)
                epoch.addResponse(T5Controller{1});
            end
        end
        
        function completeEpoch(obj, epoch)
            completeEpoch@symphonyui.core.Protocol(obj, epoch);
            
            %condense temperature measurement into single value
            T5Controller = obj.rig.getDevices('T5Controller');
            if ~isempty(T5Controller) && epoch.hasResponse(T5Controller{1})
                response = epoch.getResponse(T5Controller{1});
                [quantities, units] = response.getData();
                if ~strcmp(units, 'V')
                    error('T5 Temperature Controller must be in volts');
                end
                
                % Temperature readout from Bioptechs Delta T4/T5 Culture dish controllers is 100 mV/degree C.
                temperature = mean(quantities) * 1000 * (1/100);
                temperature = round(temperature * 10) / 10;
                epoch.addParameter('dishTemperature', temperature);
                fprintf('Temp = %2.2g C\n', temperature)
                epoch.removeResponse(T5Controller{1});
            end
        end
        
        function pts = timeToPts (obj, t)
            pts = round(t / 1e3 * obj.sampleRate);
        end
    end
    
end

