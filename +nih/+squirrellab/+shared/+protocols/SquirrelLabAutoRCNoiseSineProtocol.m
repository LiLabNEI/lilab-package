classdef (Abstract) SquirrelLabAutoRCNoiseSineProtocol < squirrellab.protocols.SquirrelLabProtocol
% Before each run, this protocol adds epochs in which short voltage stimulus is delivered.
% The stimulus is composed of a noise segment and a low frequency sine segment. 
% Based on these, it should be possible to perform
% accurate leak subtraction with clean capture of capacitative component
% (derived as linear filter of noise stimulation) and of steady-state
% current (by deriving linear relation between low freq. voltage
% stimulation and measure leak current).

    properties
       autoRC = true;
    end
    
    properties (Hidden)
		runRC
        RCpreTime = 50
        RCnoiseTime = 200
        RCinterTime = 100
        RCsineTime = 1000
        RCtailTime = 50
        RCsd = .5
        RCfreqcutoff = 10000
        RCnumberOfFilters = 4
        RCnumberOfAverages = 1
        RCsineAmplitude = 5
        RCsineFreq = 5
        RCphaseShift = 0
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

                % plot line of zero
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
            % add temperature controller monitor
            T5Controller = obj.rig.getDevices('T5Controller');
            if ~isempty(T5Controller)
                epoch.addResponse(T5Controller{1});
            end
                      
            if obj.runRC && obj.RCEpochsPrepared < obj.RCnumberOfAverages
                % Add RC epoch parameters
                [seed, stim] = obj.createRCNoiseStimulus();
                epoch.addParameter('RCepoch', 1);
                epoch.addParameter('RCpreTime', obj.RCpreTime);
                epoch.addParameter('RCnoiseTime', obj.RCnoiseTime);
                epoch.addParameter('RCinterTime', obj.RCinterTime);
                epoch.addParameter('RCsineTime', obj.RCsineTime);
                epoch.addParameter('RCtailTime', obj.RCtailTime);
                
                epoch.addParameter('RCsd', obj.RCsd);
                epoch.addParameter('RCfreqcutoff', obj.RCfreqcutoff);
                epoch.addParameter('RCseed', seed);
                epoch.addParameter('RCnumberOfFilters', obj.RCnumberOfFilters);
                
                epoch.addParameter('RCsineAmplitude', obj.RCsineAmplitude);
                epoch.addParameter('RCsineFreq', obj.RCsineFreq);
                epoch.addParameter('RCphaseShift', obj.RCphaseShift);
                
                
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
            gennoise = squirrellab.stimuli.GaussianNoiseGeneratorV2();
            
            gennoise.preTime = obj.RCpreTime;
            gennoise.stimTime = obj.RCnoiseTime;
            gennoise.tailTime = obj.RCinterTime+obj.RCsineTime+obj.RCtailTime;
            gennoise.stDev = obj.RCsd;
            gennoise.freqCutoff = obj.RCfreqcutoff;
            gennoise.numFilters = obj.RCnumberOfFilters;
            gennoise.mean = obj.rig.getDevice(obj.amp).background.quantity;
            gennoise.seed = seed;
            gennoise.sampleRate = obj.sampleRate;
            gennoise.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            stim_noise = gennoise.generate();
            
            
            gensine = symphonyui.builtin.stimuli.SineGenerator();
            
            gensine.preTime = obj.RCpreTime+obj.RCnoiseTime+obj.RCinterTime;
            gensine.stimTime = obj.RCsineTime;
            gensine.tailTime = obj.RCtailTime;
            gensine.period = 1000/obj.RCsineFreq; % converting to ms
            gensine.phase = obj.RCphaseShift;
            gensine.mean = 0;
            gensine.amplitude = obj.RCsineAmplitude;
            gensine.sampleRate = obj.sampleRate;
            gensine.units = obj.rig.getDevice(obj.amp).background.displayUnits;
            
            stim_sine = gensine.generate();
            
            
            g=symphonyui.builtin.stimuli.SumGenerator();
            g.stimuli={stim_noise,stim_sine};
            
            stim=g.generate;
        end
        
        function num = getRCTotalPts(obj)
            num = (obj.RCpreTime + obj.RCnoiseTime + obj.RCinterTime + obj.RCsineTime + obj.RCtailTime) * ...
                obj.sampleRate / 1000;
        end
    end
    
end

