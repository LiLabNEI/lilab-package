function pop = VisibleController(state)
    global u
    disp('state.frame')
    if state.frame == 1
        u.clear;
    end
    if state.time >= .5 && state.time < 1.5
        if ~flag
            st=state;
            flag=1;
        end 
        pop=1;
        u.ring_white(110,110,15,20);
        fprintf('ring time\n')
    else
        pop=0;
        u.spot_white(110,110,10);
        fprintf('spot time\n')
    end
end
