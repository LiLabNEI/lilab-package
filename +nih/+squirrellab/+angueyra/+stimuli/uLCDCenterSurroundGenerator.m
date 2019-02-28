classdef uLCDCenterSurroundGenerator < squirrellab.stimuli.uLCDStimulus
    properties
        preTime             % Spot leading duration (ms)
        stimTime            % Spot duration (ms)
        tailTime            % Spot trailing duration (ms)
        ringdelayTime       % Ring leading duration (ms)
        ringstimTime        % Ring duration (ms)
        spotRadius          % Spot radius size (pixels)
        ringRadius          % Spot radius size (pixels)
        centerX             % Spot x center (pixels)
        centerY             % Spot y center (pixels)
        spotFlag = 1;
        ringFlag = 1;
        clearFlag = 1;
    end
    
    methods
    end
    
end

