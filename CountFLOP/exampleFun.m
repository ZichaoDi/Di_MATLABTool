function [Beta_draws,ME1,ME2] = exampleFun(Y,X,ndraws,burn_in)

% Purpose: 
% Bayesian Estimate of the Probit model and the marginal effects
% -----------------------------------
% Model:
% Yi* = Xi * Beta + ui , where normalized ui ~ N(0,1)
% Yi* is unobservable. 
% If Yi* > 0, we observe Yi = 1; If Yi* <= 0, we observe Yi = 0
% -----------------------------------
% Algorithm: 
% Gibbs sampler. Proper prior Beta ~ N(mu,V).
% Posterior Beta has conjugate normal.
% Posterior latent variable follows truncated normal.
% -----------------------------------
% Usage:
% Y = dependent variable (n * 1 vector)
% X = regressors (n * k matrix)
% ndraws = number of draws in MCMC
% burn_in = number of burn-in draws in MCMC
% -----------------------------------
% Returns:
% Beta_draws = posterior draws of coefficients corresponding to the k regressors
% ME1 = marginal effects (average data)
% ME2 = marginal effects (individual average)
% -----------------------------------
% Notes: 
% Probit model is subject to normalization.
% The variance of disturbances is set to 1, and a constant is added to X.
% 
% Version: 06/2012
% Written by Hang Qian, Iowa State University
% Contact me:  matlabist@gmail.com


if nargin<2;    error('Incomplete data.');      end
if nargin<3;    ndraws = 300;                                          end
if nargin<4;    burn_in = ndraws * 0.5;                                  end

MissingValue = any(isnan([Y,X]),2);
if any(MissingValue)
    disp('There are missing values in your data.')
    disp(['Discard observations: ',num2str(find(MissingValue'))])
    FullValue = ~MissingValue;    Y = Y(FullValue);    X = X(FullValue,:);
end

[nobs,nreg] = size(X);

%----------------------------------------
% Prior distribution settings
%  Beta ~ N(mu,V)
% You may change the hyperparameters here if needed
prior_mu = zeros(nreg,1);
prior_V = 100 * eye(nreg);
%-----------------------------------------



Beta_draws = zeros(nreg,ndraws-burn_in);
Z = X * ((X'*X)\(X'*Y));
XX = X' * X;
inv_prior_V = inv(prior_V);
truncate_lower =  -999 * (Y == 0);
truncate_upper =   999 * (Y == 1);

for r = 1:ndraws
    
    beta_D = inv(XX + inv_prior_V);
    beta_d = X' * Z + inv_prior_V * prior_mu; %#ok<MINV>
    P = chol(beta_D);
    Beta_use = beta_D * beta_d + P' * randn(nreg,1); %#ok<MINV>
        
    Z = TN_RND(X*Beta_use,1,truncate_lower,truncate_upper,nobs);
    
    if r > burn_in        
        Beta_draws(:, r - burn_in) = Beta_use;
    end
end

Beta_mean = mean(Beta_draws,2);
Beta_std = std(Beta_draws,0,2);


% ME1 = normpdf(mean(X)*Beta_mean,0,1) * Beta_mean;
% ME2 = mean(normpdf(X*Beta_mean,0,1)) * Beta_mean;
ME1 = 1/sqrt(2*pi)*exp(-0.5*(mean(X)*Beta_mean).^2) * Beta_mean;
ME2 = mean(1/sqrt(2*pi)*exp(-0.5*(X*Beta_mean).^2)) * Beta_mean;


result = cell(nreg + 1,5);
result(1,:) = {'Coeff.','Post. mean','Post. std','ME(avg. data)','ME(ind. avg.)'};          
for m = 1:nreg
    result(m + 1,1) = {['C(',num2str(m),')']};
    result(m + 1,2:5) = {Beta_mean(m),Beta_std(m),ME1(m),ME2(m)};    
end

disp(' ')
disp(result)


save('exampleFunMat','-append')

end

%-------------------------------------------------------------------------
% Subfunction
function sample = TN_RND(mu,sigma,lb,ub,ndraws)

% Purpose: 
% Generate random numbers from truncated normal distribution
% TN(lb,ub) (mu, sigma)
% -----------------------------------
% Density:
% f(x) = 1/(Phi(ub)-Phi(lb)) * phi(x,mu,sigma)
% -----------------------------------
% Algorithm: 
% Inverse CDF
% -----------------------------------
% Usage:
% mu = location parameter
% sigma = scale parameter
% lb = lower bound of the random number
% ub = upper bound of the random number
% ndraws = number of draws
% -----------------------------------
% Returns:
% sample = random numbers from TN(lb,ub) (mu, sigma)
% -----------------------------------
% Notes:
% 1. If at least one of the arguments mu,sigma,lb,ub are vectors/matrix,
%    It will return a vector/matrix random numbers with conformable size.
% 2. If there is no lower/upper bound, use Inf or some large number instead
%
% Version: 06/2012
% Written by Hang Qian, Iowa State University
% Contact me:  matlabist@gmail.com

if nargin < 4; ub = 999;end
if nargin < 3; lb = -999;end
if nargin < 2; sigma = 1;end
if nargin < 1; mu = 0;end

prob_ub = normcdf(ub,mu,sigma);
prob_lb = normcdf(lb,mu,sigma);
prob_diff = prob_ub - prob_lb;

ndraws_check = length(prob_diff);
if nargin < 5 | ndraws_check > 1 %#ok<OR2>
    ndraws = ndraws_check;
    U = prob_diff;
    U(:) = rand(ndraws,1);
else
    U = rand(ndraws,1);
end

U_rescale = prob_lb + U .* prob_diff;
sample = norminv(U_rescale,mu,sigma);

save('exampleFunMat')

end

