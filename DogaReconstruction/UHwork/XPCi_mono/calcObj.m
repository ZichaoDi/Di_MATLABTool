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
    
    if m == 1
        obj.mu(m,:) = vars.mu; % (4*pi/energy.lambda).*vars.beta;
        obj.beta(m,:) = vars.beta;
        obj.delta(m,:) = vars.delta;
        
    else
        obj.mu(m,:) = obj.mu(1,:)-vars.mu; % (4*pi/energy.lambda).*vars.beta;
        obj.beta(m,:) = obj.beta(1,:)-vars.beta;
        obj.delta(m,:) = obj.delta(1,:)-vars.delta;
        
    end
end

end

% function obj = calcObj(obj,energy)
% % The function provides the obj structure with the material properties
% % based on the analytical specifications of the phantom
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
%     if m == 1
%         obj.mu(m,:) = vars.mu; % (4*pi/energy.lambda).*vars.beta;
%         obj.beta(m,:) = vars.beta;
%         obj.delta(m,:) = vars.delta;
%         
%     else
%         obj.mu(m,:) = obj.mu(1,:)-vars.mu; % (4*pi/energy.lambda).*vars.beta;
%         obj.beta(m,:) = obj.beta(1,:)-vars.beta;
%         obj.delta(m,:) = obj.delta(1,:)-vars.delta;
%         
%     end
% end
% 
% end


% function obj = calcObj(obj,energy)
% % The function provides the obj structure with the material properties
% % based on the analytical specifications of the phantom
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
%     obj.mu(m,:) = vars.mu; % (4*pi/energy.lambda).*vars.beta;
%     obj.beta(m,:) = vars.beta;
%     obj.delta(m,:) = vars.delta;
% 
% end
% 
% end