function prj = calcProj(energy,pars,obj)
% calculates the projections

% number of ellipses in the object
numberOfEllipses = size(obj.axe,1);

% initiate detector locations
detx = -pars.R2*ones(pars.detN,pars.detN);
[dety detz] = meshgrid(-pars.detLen/2:pars.pixelSize:pars.detLen/2,...
    -pars.detLen/2:pars.pixelSize:pars.detLen/2);

% define prjs
prj.mu = zeros(pars.detN,pars.detN,energy.n);
prj.beta = zeros(pars.detN,pars.detN,energy.n);
prj.delta = zeros(pars.detN,pars.detN,energy.n);

% intiate source locations (start from x-axis and go counter-clockwise)
srcx = pars.R1;
srcy = 0;
srcz = 0;

for n = 1:numberOfEllipses
    
    % intersection points of the line with the ellipse
    xDiff = detx-srcx;
    yDiff = dety-srcy;
    zDiff = detz-srcz;
    
    xDiff0 = srcx-obj.cen(n,1);
    yDiff0 = srcy-obj.cen(n,2);
    zDiff0 = srcz-obj.cen(n,3);
    
    A2 = obj.axe(n,1)^2;
    B2 = obj.axe(n,2)^2;
    C2 = obj.axe(n,3)^2;
    
    A2B2 = A2*B2;
    B2C2 = B2*C2;
    A2C2 = A2*C2;
    
    a = B2C2*xDiff.^2+A2C2*yDiff.^2+A2B2*zDiff.^2;
    b = 2*(B2C2*xDiff0.*xDiff+A2C2*yDiff0.*yDiff+A2B2*zDiff0.*zDiff);
    c = B2C2*xDiff0.^2+A2C2*yDiff0.^2+A2B2*zDiff0.^2-A2*B2*C2;
    
    alpha1 = (-b+sqrt(b.^2-4*a.*c))./(2*a);
    alpha2 = (-b-sqrt(b.^2-4*a.*c))./(2*a);
    
    len = sqrt((alpha2-alpha1).^2.*(xDiff.^2+yDiff.^2+zDiff.^2));
    len = reshape(real(len),pars.detN*pars.detN,1);
    
    prj.beta = reshape(bsxfun(@times,len,obj.beta(n,:)),pars.detN,pars.detN,energy.n)+prj.beta;
    prj.delta = reshape(bsxfun(@times,len,obj.delta(n,:)),pars.detN,pars.detN,energy.n)+prj.delta;
    prj.mu = reshape(bsxfun(@times,len,obj.mu(n,:)),pars.detN,pars.detN,energy.n)+prj.mu;
    
end

% comp0 = getMatComp('breast_hammerstein');
% vars0 = getMatPars(energy,comp0);
% 
% for m = 1:energy.n
%     prj.beta(:,:,m) = pars.thickness.*vars0.beta(m)+prj.beta(:,:,m);
%     prj.delta(:,:,m) = pars.thickness.*vars0.delta(m)+prj.delta(:,:,m);
%     prj.mu(:,:,m) = pars.thickness.*vars0.mu(m)+prj.mu(:,:,m);
% end


end