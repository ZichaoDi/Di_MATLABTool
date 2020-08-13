function [ HessGrad ] = lbfgs_two_loop_recursion( problem, grad, s_array, y_array,w )
    % global Pw N_scan
    global indice_j H_init 
% Two loop recursion algorithm for L-BFGS.
%
% Reference:
%       Jorge Nocedal and Stephen Wright,
%       "Numerical optimization,"
%       Springer Science & Business Media, 2006.
%
%       Algorithm 7.4 in Section 7.2.
%    
% This file is part of GDLibrary and SGDLibrary.
%
% Created H.Kasai on Oct. 17, 2016


    if(size(s_array,2)==0)
        HessGrad = -grad;
    else
        q = grad;

        for i = size(s_array,2):-1:1
            rk(i) = 1/(y_array(:,i)'*s_array(:,i));
            a(i) = rk(i)*s_array(:,i)'*q;
            q = q - a(i)*y_array(:,i);
        end

        %%=======standard lBFGS initialization
        if(strcmp(H_init,'standard'))
            Hk0 = (s_array(:,end)'*y_array(:,end))/(y_array(:,end)'*y_array(:,end));
        elseif(strcmp(H_init,'probe_diag'))
            %%=======known Hessian w.r.t subsmaple
            % Hk0 = 1./(sum(Pw(:,indice_j),2)+1)*length(indice_j); 
            %%=======known diagonal Hessian
            Pw = probe_weight(problem.probe,indice_j,problem.N,problem.ind_b);
            %%=======component Lipschitz constants
            % Pw = eval_Lipschitz(problem,w,indice_j);%
            %%=======full diagonal Hessian
            % Pw = problem.hess_diag(w,indice_j);
            %%====================================
            Pw=Pw./length(indice_j);
            alpha=1e-2;
            Pw = (1-alpha)*Pw+alpha*max(abs(problem.probe(:)).^2);
            Hk0 = 1./Pw;
            Hk0(isinf(Hk0))=0;
        elseif(strcmp(H_init,'p-s-hybrid'))
            % Hk0 = 1./Pw*length(indice_j)/N_scan; 
            % Hk0(Hk0==inf)=1;
            % Pw = probe_weight(problem.probe,indice_j,problem.N,problem.ind_b);
            Hk0 = 1./Pw;
            Hk0(isinf(Hk0))=0;
            Hk0 = Hk0+(s_array(:,end)'*y_array(:,end))/(y_array(:,end)'*y_array(:,end));
        end
        R = Hk0.*q;

        for jj = 1:size(s_array,2)
            beta = rk(jj)*y_array(:,jj)'*R;
            R = R + s_array(:,jj)*(a(jj) - beta);
        end

        HessGrad = -R; 
    end
end

