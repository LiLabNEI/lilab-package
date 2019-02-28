function spotFlag = uLCDSpotController(state)
    global u
    uStim=state.handles{1};
    if state.time >= uStim.preTime && state.time < (uStim.preTime+uStim.stimTime) && uStim.spotFlag
        u.spot_white(uStim.centerX,uStim.centerY,uStim.spotRadius);
        uStim.spotFlag=0;
    elseif state.time >= (uStim.preTime+uStim.stimTime) && ~uStim.spotFlag
        u.clear;
        uStim.spotFlag=1;
    end
    spotFlag=~uStim.spotFlag;
end
