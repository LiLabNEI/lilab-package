classdef stgCheckerboardNoise < nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp
    
    properties
        preTime = 500                   % Spot leading duration (ms)
        stimTime = 20000                % Spot duration (ms)
        tailTime = 500                  % Spot trailing duration (ms)
        
        stixelSize = 20                 % pixels
        binaryNoise = true              % binary checkers - overrides noiseStdv
        noiseStdv = 0.3                 % contrast, as fraction of mean
        frameDwell = 5                  % Frames per noise update
        useRandomSeed = true            % false = repeated noise trajectory (seed 0)
        backgroundIntensity = 0.5       % (0-1)

        numberOfAverages = uint16(20)    % Number of epochs
        interpulseInterval = 0          % Duration between spots (s)
    end
    
    
    properties (Hidden)
        noiseSeed
        noiseStream
        numChecksX
        numChecksY
    end

    methods
        
        function didSetRig(obj)
            didSetRig@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj);
        end
        

        
        function prepareRun(obj)
            prepareRun@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj);
            
            %get number of checkers...
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            %convert from microns to pixels...
%             stixelSizePix = obj.rig.getDevice('Stage').um2pix(obj.stixelSize);
            stixelSizePix = obj.stixelSize;
            obj.numChecksX = round(canvasSize(1) / stixelSizePix);
            obj.numChecksY = round(canvasSize(2) / stixelSizePix);
        end
        
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj, name);        
            

            % Can also set d.displayName, d.description
            if contains(lower(name), 'spot') || contains(lower(name), 'background')
                d.category = 'Pattern stimulus';
                
                if contains(lower(name), 'diameter') || contains(lower(name), 'center')
                    d.displayName = [d.displayName ' (pixels)'];
                elseif contains(lower(name), 'intensity')
                    d.displayName = [d.displayName ' [0-1]'];
                end

                %No default behavior; is handled in superclass
            end

        end 
        
        
        function p = createPresentation(obj)
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3); %create presentation of specified duration
            p.setBackgroundColor(obj.backgroundIntensity); % Set background intensity
            
            % Create checkerboard
            initMatrix = uint8(255.*(obj.backgroundIntensity .* ones(obj.numChecksY,obj.numChecksX)));
            board = stage.builtin.stimuli.Image(initMatrix);
            board.size = canvasSize;
            board.position = canvasSize/2;
            board.setMinFunction(GL.NEAREST); %don't interpolate to scale up board
            board.setMagFunction(GL.NEAREST);
            p.addStimulus(board);
            preFrames = round(60 * (obj.preTime/1e3));
            checkerboardController = stage.builtin.controllers.PropertyController(board, 'imageMatrix',...
                @(state)getNewCheckerboard(obj, state.frame - preFrames));
            p.addController(checkerboardController); %add the controller
            function i = getNewCheckerboard(obj, frame)
                persistent boardMatrix;
                if frame<0 %pre frames. frame 0 starts stimPts
                    boardMatrix = obj.backgroundIntensity;
                else %in stim frames
                    if mod(frame, obj.frameDwell) == 0 %noise update
                        if (obj.binaryNoise)
                            boardMatrix = 2*obj.backgroundIntensity * ...
                                (obj.noiseStream.rand(obj.numChecksY,obj.numChecksX) > 0.5);
                        else
                            boardMatrix = obj.backgroundIntensity + ...
                                obj.noiseStdv * obj.backgroundIntensity * ...
                                obj.noiseStream.randn(obj.numChecksY,obj.numChecksX);
                        end
                    end
                end
                i = uint8(255 * boardMatrix);
            end

            % hide during pre & post
            boardVisible = stage.builtin.controllers.PropertyController(board, 'visible', ...
                @(state)state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
            p.addController(boardVisible); 
            
            p = obj.addFrameTracker(p);
            p = obj.addTrackerBarToFirstFrame(p);
            
        end
        
        
        
        function p = addFrameTracker(obj, p) 
            p = addFrameTracker@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj, p, obj.preTime, obj.preTime + obj.stimTime);
        end
        
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj, epoch);
            
            % Determine seed values.
            if obj.useRandomSeed
                obj.noiseSeed = RandStream.shuffleSeed;
            else
                obj.noiseSeed = 0;
            end
            
            %at start of epoch, set random stream
            obj.noiseStream = RandStream('mt19937ar', 'Seed', obj.noiseSeed);
            epoch.addParameter('noiseSeed', obj.noiseSeed);
            epoch.addParameter('numChecksX', obj.numChecksX);
            epoch.addParameter('numChecksY', obj.numChecksY);
        end
        
        
        
        
        function prepareInterval(obj, interval)
            prepareInterval@nih.squirrellab.shared.protocols.UvLCRStageProtocol_NoAmp(obj, interval);
        end
        
        
        
    end
    
end