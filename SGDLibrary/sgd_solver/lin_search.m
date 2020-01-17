function [xnew, nf1, alpha1,ierror] = ...
    lin_search(p, x, alpha, g, problem, indice)
%---------------------------------------------------------
% line search (naive)
%---------------------------------------------------------
% set up
%---------------------------------------------------------
xnew   = x;
fnew   = problem.cost(x);
gnew   = g;
maxit  = 15;
ierror=1;
%%%%%%%%%%%%%%%%%%%#####fix step length as 1 ##############################
% disp('### In LINE SEARCH: lin1 ###')
% fprintf(' g''p = %e\n',g'*p);
alpha1 = alpha;
q0=p'*g;
%---------------------------------------------------------
% line search
%---------------------------------------------------------
for itcnt = 1:maxit;
    xt = x + alpha1.*p;
    %%%%%%%%%%%#############################################################
    ft = problem.cost(xt);
    gt = problem.grad(xt,indice);
    % Armijo =ft<f+1e-4*alpha1*q0;
    Wolfe = abs(p'*gt)<0.25*abs(q0);
    if (ft < fnew);
    % if(Wolfe)
        xnew   = xt;
        fnew   = ft;
        gnew   = gt;
        ierror=0;
        break;
    end;
    alpha1 = alpha1 ./ 2;
end;
nf1 = itcnt;

