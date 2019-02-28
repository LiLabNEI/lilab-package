classdef (Abstract) SquirrelLabAutoRCNoiseProtocol < squirrellab.protocols.SquirrelLabProtocol
% delivers a 5 mV voltage pulse every time protocol is run to keep track
% of access resistance and membrane capacitance

    properties
       autoRC = true;
    end
    
    properties (Hidden)
		runRC
        RCpreTime = 25
        RCstimTime = 200
        RCtailTime = 25
        RCsd = .5
        RCfreqcutoff = 10000
        RCnumberOfFilters = 4
        RCnumberOfAverages = 1
        RCinterpulseInterval = 0
        RCEpochsPrepared
        RCEpochsCompleted
    end
    
    methods
        
        function prepareRun(obj)
            prepareRun@squirrellab.protocols.SquirrelLabProtocol(obj);
            obj.RCEpochsCompleted = 0;
            obj.RCEpochsPrepared = 0;
            if obj.autoRC
                obj.runRC = true;
                % Open RC figure
                obj.showFigure('squirrellab.figures.RCFigure', @obj.updateFigure);
            else
                obj.runRC = false;
            end
        end
        
        function updateFigure(obj, custFigObj, epoch)
            if obj.numEpochsCompleted == 0 && obj.RCEpochsCompleted == 1
                obj.plotData.figure = custFigObj.getFigureHandle();
                clf(obj.plotData.figure); %clear figure
                obj.plotData.axes = axes('Parent', obj.plotData.figure, 'NextPlot', 'replace');

                % plot three lines of zero
                totPts = obj.getRCTotalPts();
                timePts = (1:totPts) / obj.sampleRate;
                obj.plotData.lines = cell(1,1);
                colors = [0 0 0];
                obj.plotData.lines = plot(obj.plotData.axes, ...
                    timePts, zeros(1,totPts), ...
                    'Color', colors, 'LineWidth', 1);
                obj.plotData.lines.UserData = 0;
            end
            if epoch.parameters.isKey('RCepoch')
                if epoch.parameters('RCepoch')
                    % update the line
                    obj.plotData.lines.YData = epoch.getResponse(obj.rig.getDevice(obj.amp)).getData();
                end
            end
        end
        
        
        function prepareEpoch(obj, epoch)
            % add remperature controller monitor
            T5Controller = obj.rig.getDevices('T5Controller');
            if ~isempty(T5Controller)
                epoch.addResponse(T5Controller{1});
            end
                      
            if obj.runRC && obj.RCEpochsPrepared < obj.RCnumberOfAverages
                % Add RC epoch parameters
                [seed, stim] = obj.createRCNoiseStimulus();
                epoch.addParameter('RCepoch', 1);
                epoch.addParameter('RCpreTime', obj.RCpreTime);
                epoch.addParameter('RCstimTime', obj.RCstimTime);
                epoch.addParameter('RCtailTime', obj.RCtailTime);
                epoch.addParameter('RCsd', obj.RCsd);
                epoch.addParameter('RCfreqcutoff', obj.RCfreqcutoff);
                epoch.addParameter('RCseed', seed);
                epoch.addParameter('RCnumberOfFilters', obj.RCnumberOfFilters);
                epoch.addParameter('RCnumberOfAverages', obj.RCnumberOfAverages);
                epoch.addParameter('RCinterpulseInterval', obj.RCinterpulseInterval);
                epoch.addStimulus(obj.rig.getDevice(obj.amp), stim);
                epoch.addResponse(obj.rig.getDevice(obj.amp));
                obj.RCEpochsPrepared = obj.RCEpochsPrepared + 1;
%                 fprintf('yas RC: %g of %g\n',obj.RCEpochsPrepared,obj.RCnumberOfAverages)
			else
				obj.runRC = false;
                obj.numEpochsPrepared = obj.numEpochsPrepared + 1;
%                 fprintf('not RC: %g of %g\n',obj.numEpochsPrepared,obj.numberOfAverages)

            end
        end
        
        function completeEpoch(obj, epoch)
            if epoch.parameters.isKey('RCepoch')
                if epoch.parameters('RCepoch')
                    obj.RCEpochsCompleted = obj.RCEpochsCompleted + 1;
                    fprintf('RC (%g of %g)\n',obj.RCEpochsCompleted, obj.RCnumberOfAverages)
                    obj.figureHandlerManager.updateFigures(epoch);
                else
                    warning('Epoch is labeled as RCepoch but RCepoch is false\n')
                end
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
            else
                completeEpoch@squirrellab.protocols.SquirrelLabProtocol(obj, epoch);
            end 
        end
        
        function completeRun(obj)
            completeRun@squirrellab.protocols.SquirrelLabProtocol(obj);
        end
        
        function [seed, stim] = createRCNoiseStimulus(obj)
            
            seed = RandStream.shuffleSeed;
            gen = squirrellab.stimuli.GaussianNoiseGeneratorV2();
            
            gen.preTime = obj.RCpreTime;
            gen.stimTime = obj.RCstimTime;
            gen.tailTime = obj.RCtailTime;
            gen.stDev = obj.RCsd;
            gen.freqCutoff = obj.RCfreqcutoff;
            gen.numFilters = obj.RCnumberOfFilters;
            gen.mean = obj.rig.getDevice(obj.amp).background.quantity;
            gen.seed = seed;
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            stim = gen.generate();
        end
        
        function num = getRCTotalPts(obj)
            num = (obj.RCpreTime + obj.RCstimTime + obj.RCtailTime) * ...
                obj.sampleRate / 1000;
        end
    end
    
end

