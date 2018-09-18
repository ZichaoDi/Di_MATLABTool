function sinogram = calcRadon(obj,detLen,detN,viewAngle)

% initiate grid size
detNSize = detLen/(detN-1);

% initiate detector locations
dety0 = -detLen/2:detNSize:detLen/2;
detx0 = -100*ones(1,length(dety0));

% initiate detector locations
srcy0 = -detLen/2:detNSize:detLen/2;
srcx0 = 100*ones(1,length(dety0));

% number of projection views
numberOfViews = length(viewAngle);

% define sinograms
sinogram.mu = zeros(detN,numberOfViews);
sinogram.rho = zeros(detN,numberOfViews);
sinogram.beta = zeros(detN,numberOfViews);
sinogram.delta = zeros(detN,numberOfViews);

% number of ellipses in the object
numberOfEllipses = size(obj.axe,1);

for m = 1:numberOfViews
    
    % update detector coordinates
    srcx = srcx0.*cos((viewAngle(m)))+srcy0.*sin((viewAngle(m)));
    srcy = srcx0.*sin((viewAngle(m)))-srcy0.*cos((viewAngle(m)));
    
    % update detector coordinates
    detx = detx0.*cos((viewAngle(m)))+dety0.*sin((viewAngle(m)));
    dety = detx0.*sin((viewAngle(m)))-dety0.*cos((viewAngle(m)));
    
%     hold on
%     scatter(detx',dety','r');
%     scatter(srcx',srcy','b');
%     grid on
%     axis equal

    for n = 1:numberOfEllipses
        
        % intersection points of the line with the ellipse
        xDiff = detx-srcx;
        yDiff = dety-srcy;
        
        xDiff0 = srcx-obj.cen(n,1);
        yDiff0 = srcy-obj.cen(n,2);
        
        A2 = obj.axe(n,1)^2;
        B2 = obj.axe(n,2)^2;
        
        a = B2*xDiff.^2+A2*yDiff.^2;
        b = 2*(B2*xDiff.*xDiff0+A2*yDiff.*yDiff0);
        c = B2*xDiff0.^2+A2*yDiff0.^2-A2*B2;
        
        alpha1 = (-b+sqrt(b.^2-4*a.*c))./(2*a);
        alpha2 = (-b-sqrt(b.^2-4*a.*c))./(2*a);
        
        len = sqrt((alpha2-alpha1).^2.*(xDiff.^2+yDiff.^2));
        
        sinogram.beta(:,m) = obj.beta(n)*real(len)'+sinogram.beta(:,m);
        sinogram.delta(:,m) = obj.delta(n)*real(len)'+sinogram.delta(:,m);
        sinogram.rho(:,m) = obj.rho(n)*real(len)'+sinogram.rho(:,m);
        sinogram.mu(:,m) = obj.mu(n)*real(len)'+sinogram.mu(:,m);
        
    end
end
