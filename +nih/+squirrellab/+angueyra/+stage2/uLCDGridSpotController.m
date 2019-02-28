function spotFlag = uLCDGridSpotController(state)
    global u
    uStim=state.handles{1};
    % clear screen in first
    if state.time >= 0 && uStim.initialclearFlag
        u.clear;
        uStim.initialclearFlag=0;
    % then create spot as soon as possible during preTime
    elseif state.time <= uStim.preTime && uStim.spotFlag
        u.spot_white(uStim.centerX,uStim.centerY,uStim.spotRadius);
        uStim.spotFlag=0;
    % clear screen after led has flashed
    elseif state.time > (uStim.preTime+uStim.stimTime) && uStim.clearFlag
        u.clear;
        uStim.clearFlag=1;
    end
    spotFlag=uStim.spotFlag;
end
