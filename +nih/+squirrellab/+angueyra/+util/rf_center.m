function [cx,cy] = rf_center(x,y,z,nX,nY)
	% function [cx,cy] = rf_center(x,y,z,nX,nY)
	% Calculates center of receptive field as a mass centre (weigthed mean of measurements with coordinates x,y and magnitude z)
    xmat=reshape(x,nX,nY);
    ymat=reshape(y,nX,nY);
    zmat=reshape(z,nX,nY);
    
    cx = sum(zmat(:) .* xmat(:)) / sum(zmat(:));
    cy = sum(zmat(:) .* ymat(:)) / sum(zmat(:));
end