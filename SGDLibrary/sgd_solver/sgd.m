function [w, infos] = sgd(problem, in_options)
    global Pw
% Stochastic gradient descent (SGD) algorithm.
%
% Inputs:
%       problem     function (cost/grad/hess)
%       in_options  options
% Output:
%       w           solution of w
%       infos       information
%
% This file is part of SGDLibrary.
%
% Created by H.Kasai on Feb. 15, 2016
% Modified by H.Kasai on Mar. 25, 2018


    % set dimensions and samples
    d = problem.dim();
    n = problem.samples();  

    % set local options 
    local_options = [];
    
    % merge options
    options = mergeOptions(get_default_options(d), local_options);   
    options = mergeOptions(options, in_options);  
    
    % initialize
    total_iter = 0;
    epoch = 0;
    grad_calc_count = 0;
    w = options.w_init;
    num_of_bachces = ceil(n / options.batch_size); 

    % store first infos
    clear infos;    
    [infos, f_val, optgap] = store_infos(problem, w, options, [], epoch, grad_calc_count, 0);
    
    % display infos
    if options.verbose > 0
        fprintf('SGD: Epoch = %03d, cost = %.16e, optgap = %.4e\n', epoch, f_val, optgap);
    end    

    % set start time
    start_time = tic();
    InvHess=options.S;

    % main loop
    optgap_old=0;
    while (abs(optgap-optgap_old) > options.tol_optgap) && (epoch < options.max_epoch)

        % permute samples
        if options.permute_on
            perm_idx = randperm(n);
        else
            perm_idx = 1:n;
        end

        if(options.uo & epoch==0)
            % updateOrder=shuffle_wo_overlap(problem.N_scan,options.batch_size);
            % load u
            updateOrder=sample_wo_overlap(problem.N_scan,options.batch_size, problem.ind_b);
            num_of_bachces=length(updateOrder);
        end
        for j = 1 : num_of_bachces
            
            % update step-size
            step = options.stepsizefun(total_iter, options);
            
            % calculate gradient
            if(options.uo)
                indice_j = updateOrder{j};
                indice_j = indice_j(randperm(length(indice_j)));
            elseif(options.wr)
                indice_j = randi(n,1,options.batch_size);
            else
                start_index = (j-1) * options.batch_size + 1;
                if(start_index+options.batch_size-1>problem.samples)
                    indice_j = perm_idx(start_index:end);
                else
                    indice_j = perm_idx(start_index:start_index+options.batch_size-1);
                end
            end
            grad =  problem.grad(w, indice_j);

            % update w
            global H_init
            
            if(strcmp(H_init,'standard')); 
                InvHess=1;
            elseif(strcmp(H_init,'probe-diag' ))
                [Pw,c] = probe_weight(problem.probe,indice_j,problem.N,problem.ind_b);
                % if isempty(InvHess)
                    % Pw = eval_Lipschitz(problem,w,indice_j);%
                    % Pw = problem.hess_diag(w,indice_j);
                    alpha=1e-2;
                    Pw = (1-alpha)*Pw+alpha*max(abs(problem.probe(:)).^2).*(Pw~=0);
                    InvHess = 1./Pw;
                    InvHess(isinf(InvHess))=0;
                    %%==================================
                    % figure(3);subplot(1,2,1),imagesc(reshape(Pw(1:end/2),problem.N,problem.N)); 
                    % title(num2str(length(indice_j)));
                    % subplot(1,2,2),hold off;ti=problem.ind_b(indice_j,:);
                    % for tpj=1:length(indice_j),
                    %     plot([ti(tpj,1),ti(tpj,2),ti(tpj,2),ti(tpj,1),ti(tpj,1)],[ti(tpj,3),ti(tpj,3),ti(tpj,4),ti(tpj,4),ti(tpj,3)],'r.-')
                    % axis([min(problem.ind_b(:,1)) max(problem.ind_b(:,2)) min(problem.ind_b(:,3)) max(problem.ind_b(:,4))]);
                    %     hold on;
                    % end
                    % pause(1);
                    %%==================================
                    if(~isempty(find(InvHess<0)))
                         InvHess(InvHess<0)
                         disp('negative Hessian diag');
                    end
                % end
            end
            if strcmp(options.step_alg, 'backtracking')
                rho = 1/2;
                c = 1e-4;
                step = backtracking_line_search(problem, -InvHess.*grad, w, rho, c, indice_j);
            end
            w = w - step *InvHess.* grad;
            % p_sgd(:,total_iter+1)=step*InvHess.*grad;
            % f_iter_sgd(total_iter+1)=problem.cost(w);
            % w_iter(:,total_iter+1)=w;
            % proximal operator
            if ismethod(problem, 'prox')
                w = problem.prox(w, step);
            end  
            total_iter = total_iter + 1; 
            grad_calc_count = grad_calc_count + length(indice_j);        
            
        end
        
        %     save('sgd_2.mat','f_iter_sgd','p_sgd','w_iter'); 
        %     return;
        % measure elapsed time
        elapsed_time = toc(start_time);
        
        % count gradient evaluations
        % grad_calc_count = grad_calc_count + num_of_bachces * options.batch_size;        
        epoch = epoch + 1;

        % store infos
        optgap_old=optgap;
        [infos, f_val, optgap] = store_infos(problem, w, options, infos, epoch, grad_calc_count, elapsed_time);        

        % display infos
        if options.verbose > 0
            fprintf('SGD: Epoch = %03d, cost = %.16e, optgap = %.4e\n', epoch, f_val, optgap);
        end

    end
    
    if optgap < options.tol_optgap
        fprintf('Optimality gap tolerance reached: tol_optgap = %g\n', options.tol_optgap);
    elseif epoch == options.max_epoch
        fprintf('Max epoch reached: max_epoch = %g\n', options.max_epoch);
    end
    
end
