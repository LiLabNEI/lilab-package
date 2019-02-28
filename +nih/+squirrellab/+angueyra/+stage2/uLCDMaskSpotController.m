function spotFlag = uLCDMaskSpotController(state)
    global u
    uStim=state.handles{1};
    if state.time <= uStim.preTime && uStim.clearFlag
        u.clear;
        uStim.clearFlag;
    elseif state.time >= uStim.preTime && uStim.spotFlag
        u.spot_white(uStim.centerX,uStim.centerY,uStim.spotRadius);
        uStim.spotFlag=0;
    end
    spotFlag=uStim.spotFlag;
end
