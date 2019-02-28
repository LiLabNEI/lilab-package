function circHandle=drawCircle(x,y,rad,figH)
    npoints=11;
    theta=linspace(0,2*pi,npoints);
    rho=ones(1,npoints)*rad;
    [X,Y] = pol2cart(theta,rho);
    X=X+x;
    Y=Y+y;
    circHandle=line(X,Y,'Parent',figH);
end
