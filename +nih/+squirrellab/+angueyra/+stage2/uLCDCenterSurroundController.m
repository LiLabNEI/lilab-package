function spotFlag = uLCDCenterSurroundController(state)
    global u
    uStim=state.handles{1};
    if state.time< uStim.preTime && uStim.clearFlag
        u.clear;
        uStim.clearFlag=0;
    elseif state.time >= uStim.preTime && state.time < (uStim.preTime+uStim.ringdelayTime) && uStim.spotFlag
        u.spot_white(uStim.centerX,uStim.centerY,uStim.spotRadius);
        uStim.spotFlag=0;
    elseif state.time >= uStim.preTime+uStim.ringdelayTime && state.time < (uStim.preTime+uStim.ringdelayTime+uStim.ringstimTime) && uStim.ringFlag
        u.spot_white(uStim.centerX,uStim.centerY,uStim.ringRadius);
        uStim.ringFlag=0;
        uStim.spotFlag=1;
    elseif state.time >= (uStim.preTime+uStim.ringdelayTime+uStim.ringstimTime) && state.time < (uStim.preTime+uStim.stimTime) && uStim.spotFlag
        u.clear;
        u.spot_white(uStim.centerX,uStim.centerY,uStim.spotRadius);
        uStim.spotFlag=0;
        uStim.ringFlag=0;
    elseif state.time >= (uStim.preTime+uStim.stimTime)
        u.clear;
    end
    spotFlag=uStim.spotFlag;
end
