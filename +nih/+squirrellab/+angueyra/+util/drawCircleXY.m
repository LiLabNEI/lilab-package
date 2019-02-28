function [X,Y]=drawCircleXY(x,y,rad)
    % same as draw circle but only sptis out x and y data
    npoints=11;
    theta=linspace(0,2*pi,npoints);
    rho=ones(1,npoints)*rad;
    [X,Y] = pol2cart(theta,rho);
    X=X+x;
    Y=Y+y;
end
