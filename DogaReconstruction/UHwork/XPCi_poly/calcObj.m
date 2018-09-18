% function obj = calcObj(obj,energy)
% % The function provides the obj structure with the material properties
% % based on the analytical specifications of the phantom
% 
% comp0 = getMatComp('breast_hammerstein');
% vars0 = getMatPars(energy,comp0);
% 
% % parameters for the object to be imaged
% obj.mu = [];
% obj.beta = [];
% obj.delta = [];
% for m = 1:length(obj.mat)
%     
%     comp = getMatComp(obj.mat{m});
%     vars = getMatPars(energy,comp);
%     
%     obj.mu(m,:) = vars.mu-vars0.mu; % (4*pi/energy.lambda).*vars.beta;
%     obj.beta(m,:) = vars.beta-vars0.beta;
%     obj.delta(m,:) = vars.delta-vars0.delta;
%         
% end
% 
% end

function obj = calcObj(obj,energy)
% The function provides the obj structure with the material properties 
% based on the analytical specifications of the phantom

% parameters for the object to be imaged
obj.mu = [];
obj.beta = [];
obj.delta = [];
for m = 1:length(obj.mat)
    
    comp = getMatComp(obj.mat{m});
    vars = getMatPars(energy,comp);
    
    obj.mu(m,:) = vars.mu; % (4*pi/energy.lambda).*vars.beta;
    obj.beta(m,:) = vars.beta;
    obj.delta(m,:) = vars.delta;
    
end

end