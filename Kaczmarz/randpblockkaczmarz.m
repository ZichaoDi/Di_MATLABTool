function [X info] = randpblockkaczmarz(A,b,s,K,x0,options)
%RANDPBLOCKKACZMARZ Randomized modification for block Kaczmarz method
%
%   [X info] = randpblockkaczmarz(A,b,s,K)
%   [X info] = randpblockkaczmarz(A,b,s,K,x0)
%   [X info] = randpblockkaczmarz(A,b,s,K,x0,options)
%
% Input:
%   A          m times n matrix.
%   b          m times 1 vector.
%   s          Block size. Note, that rem(m, s) should be zero.
%   K          Number of iterations. If K is a scalar, then K is the maximum
%              number of iterations and only the last iterate is saved.
%              If K is a vector, then the largest value in K is the maximum
%              number of iterations and only iterates corresponding to the
%              values in K are saved, together with the last iterate.
%              If K is empty then a stopping criterion must be specified.
%   x0         n times 1 starting vector. Default: x0 = 0.
%   options    Struct with the following fields:
%       distribution	String containing the on of following probability
%                       distribution rule (uniform by default):
%                           'uniform'   : Discrete uniform distribution. The 
%                                         probability to select block are
%                                         the same: P(k=i)=s/m, i=1,2,...,s.
%                           'proportional'  : Special discrete distribution
%                                             based on results from [3]:
%                                             P(k=i)=norm(A(s*(i-1)+1:i*s,:),'fro')^2/norm(A,'fro')^2, i=1,2,...,s.
%                           
%       stoprule        Struct containing the following information about the
%                       stopping rule:
%                           type =  'none' : (Default) the only stopping rule
%                                            is the maximum number of iterations.
%                                   'NR'   : Naive stop rule, ||x^{k} - x^{k-1}||^2 <= epsilon.
%                                   'ER'   : Stop rule if we know the exact solution x_*, ||x_* - x^{k}||^2 <= epsilon.
%                           epsilon = convergence factor, only necessary for NR or ER.
%                           solution = solution of problem, only necessary for ER.
%       nonneg          Logical; if true then nonnegativity in enforced in
%                       each step.
%
% Output:
%   X           Matrix containing the saved iterations.
%   info        Information vector with 2 elements.
%               info(1) = 0 : stopped by maximum number of iterations
%                         1 : stopped by NR-rule or ER-rule
%               info(2) = no. of iterations.
%
% See also: pblockkaczmarz, dpmsolve.
%
% THIS CODE BASED on paper P. C. Hansen and M. Saxild-Hansen, AIR Tools - A 
% MATLAB Package of Algebraic Iterative Reconstruction Methods, Journal 
% of Computational and Applied Mathematics, 236 (2012), pp. 2167-2178,
% http://www2.imm.dtu.dk/~pcha/AIRtools/.
%
%% Author
% *Ivanov Andrey*, Candidate of Physico-Mathematical Sciences,
% *ssauivanov@gmail.com*.
%
% Dept. of Applied Mathematics, S. P. Korolyov Samara State Aerospace 
% University (National Research University), 
% Faculty of Computer Science, Samara, Russia
%
%% Reference
% [1]   A. I. Zhdanov, The method of augmented regularized normal equations, Computational Math-
%       ematics and Mathematical Physics, 52 (2012), pp. 194-197.
% [2]   A. I. Zhdanov, A. A. Ivanov, Projection Regularization Algorithm 
%       for Solving Linear Algebraic System of Large Dimension, 
%       Vestn. Samar. Gos. Tekhn. Univ. Ser. Fiz.-Mat. Nauki, 2010,
%       Issue 5(21), pp. 309?312, (In Russian)
%       http://www.mathnet.ru/php/archive.phtml?wshow=paper&jrnid=vsgtu&paperid=827&option_lang=eng
% [3]   T. Strohmer and R. Vershynin, A randomized Kaczmarz algorithm
%       for linear systems with exponential convergence, J. Fourier Analysis and
%       Applications, 15 (2009), pp. 262-278.
% [4]   G. P. Vasil'chenko and A. A. Svetlakov, A projection algorithm for solving systems of
%       linear algebraic equations of high dimensionality, USSR Computational Mathematics and
%       Mathematical Physics, 20 (1980), pp. 1-8.
% [5]   Ivanov A.A., Zhdanov A.I. Kaczmarz algorithm for Tikhonov regularization problem,
%       Appl. Math. E-Notes, 13(2013), pp. 270-276.

[m n] = size(A);

%A = A';  % Faster to perform sparse column operations.

if nargin < 4
    error('Too few input arguments')
end
% Default values of x0.
if nargin < 5
    x0 = zeros(n,1);
end

% Check if x0 is empty.
if isempty(x0)
    x0 = zeros(n,1);
end

% The sizes of A, b and x must match.
if size(b,1) ~= m || size(b,2) ~= 1
    error('The size of A and b do not match')
elseif size(x0,1) ~= n || size(x0,2) ~= 1
    error('The size of x0 does not match the problem')
end

if rem(m, s) ~= 0
    error('Incorect size of block - s')
end;

lgth = m / s;

% Initialization.
if nargin < 6
    if isempty(K)
        error('No stopping rule specified')
    end
    stoprule = 'NO';
    
    Knew = sort(K);
    kmax = Knew(end);
    X = zeros(n,length(K));
    
    % Default there is no nonnegativity projection.
    nonneg = false;

end

% Check the contents of options, if present.
if nargin == 6
    
    % Nonnegativity.
    if isfield(options,'nonneg')
        nonneg = options.nonneg;
    else
        nonneg = false;
    end

    if isfield(options,'stoprule') && isfield(options.stoprule,'type')
        stoprule = options.stoprule.type;
        if ischar(stoprule)
            if strncmpi(stoprule,'NR',2);
                % Naive stopping rule.
                if isfield(options.stoprule,'epsilon')
                    epsilon = options.stoprule.epsilon;
                else
                    error(['The factor epsilon must be specified when '...
                        'using NR'])
                end
            elseif strncmpi(stoprule,'NO',2)
                % No stopping rule.
                if isempty(K)
                    error('No stopping rule specified')
                end
            elseif strncmpi(stoprule,'ER',2)
                % Error stoping rule
                if isfield(options.stoprule,'epsilon')
                    epsilon = options.stoprule.epsilon;
                else
                    error(['The factor epsilon must be specified when '...
                        'using ER'])
                end
                if isfield(options.stoprule,'solution')
                    solution = options.stoprule.solution;
                    nrm_solution = norm(solution);
                else
                    error(['The factor solution must be specified when '...
                        'using ER'])
                end
            else
                % Other stopping rules.
                error('The chosen stopping rule is not valid')
            end % end different stopping rules.
            
        else
            error('The stoprule type must be a string')
        end
        
        if isempty(K)
            kmax = inf;
            X = zeros(n,1);
        else
            Knew = sort(K);
            kmax = Knew(end);
            X = zeros(n,length(K));
        end
        
    else
        if isempty(K)
            error('No stopping rule specified')
        else
            Knew = sort(K);
            kmax = Knew(end);
            X = zeros(n,length(K));
            stoprule = 'NO';
        end
    end % end stoprule type specified.
    
end % end if nargin includes options.

distribution = zeros(lgth,1);

updaterule = options.distribution;
if ischar(updaterule)
    if (strncmpi(updaterule,'proportional',2))
        for i = 1:lgth
            test = norm(A,'fro')^2;
            if (test < eps)
                warning('This block will never be selected')
                distribution(i) = 0.0;
            else
                distribution(i) = norm(A(s*(i-1)+1:i*s,:),'fro')^2/test;
            end;
        end;
    else
        distribution = ones(1,lgth)/lgth;
    end
else
    distribution = ones(1,lgth)/lgth;
end
cumul = disrand(distribution);

xk = x0;
stop = 0;
k = 0;
l = 0;

while ~stop
    k = k + 1;
    
    random_value = rand*100;
    I = find(cumul >= random_value);
    i = I(1);
    xkm1 = xk;
    xk = dpm_solver(A(s*(i-1)+1:i*s,:),b(s*(i-1)+1:i*s),xk);

    % Stopping rules:
   if strncmpi(stoprule,'NR',2);
        dRSE = norm(xkm1 - xk)^2;
        
        if dRSE <= epsilon || k >= kmax
            stop = 1;
            
            if k ~= kmax
                info = [1 k];
            else
                info = [0 k];
            end
        end
    elseif strncmpi(stoprule,'ER',2)
        dRSE = norm(solution - xk)^2;
        
        if dRSE <= epsilon || k >= kmax
            stop = 1;
            
            if k ~= kmax
                info = [1 k];
            else
                info = [0 k];
            end
        end
    elseif strncmpi(stoprule,'NO',2)
        % No stopping rule.
        if k >= kmax 
            stop = 1;
            info = [0 k];
        end
    end % end stoprule type.
    
    % If the current iteration is requested saved.
    if (~isempty(K) && k == Knew(l+1)) || stop
        l = l + 1;
        % Saves the current iteration.
        X(:,l) = xk;
    end
end;
X = X(:,1:l);

function u = dpm_solver(A,f,u)
%DISRAND define a cumulative distibution
%
%   u = dpm_solver(A,f,u)
%
% Create a cumulative distribution of the input normAi.
%
% Reference:
% [1]  A. I. Zhdanov, P. A. Shamarov, The direct projection method in the
% problem of complete least squares, Avtomat. i Telemekh., 2000, no. 4, 
% p. 77--87 (in Russian), in English: see Automation and Remote Control,
% 2000, 61:4, 610--0620.
% http://www.mathnet.ru/php/archive.phtml?wshow=paper&jrnid=at&paperid=268&option_lang=eng

 [n,m] = size(A);
 u = [u;zeros(n,1)];
 P = [-A'; eye(n,n)];
 for k = 1:1:n-1
     delta = A(k,:)*P(1:m,k);
     u(1:m+k) = u(1:m+k) + P(1:m+k, k)*((f(k)-A(k,:)*u(1:m)) / delta);
     P(1:m+k,k+1:end) = P(1:m+k,k+1:end) - P(1:m+k,k)* (A(k,:)*P(1:m,k+1:end) ) / delta;
     P(1:m+k,k) = 0;
 end;
 delta = A(n,:)*P(1:m,n);
 u = u + P(1:m+n,n)*(f(n)-A(n,1:m)*u(1:m)) / delta;
 u = u(1:end-n);
 
function cumul = disrand(normAi)
%DISRAND define a cumulative distibution
%
%   cumul = disrand(normAi)
%
% Create a cumulative distribution of the input normAi.

T = sum(normAi);
pct = normAi/T*100;
cumul = cumsum(pct);