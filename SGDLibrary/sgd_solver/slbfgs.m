function [w, infos] = slbfgs(problem, in_options)
    global indice_j
% Stochastic limited-memory quasi-newton methods (Stochastic L-BFGS) algorithms.
%
% Inputs:
%       problem     function (cost/grad/hess)
%       in_options  options
% Output:
%       w           solution of w
%       infos       information
%
% References:
%       sub_mode:   SQN:
%                   Byrd, R. H., Hansen, S. L., Nocedal, J., & Singer, Y. 
%                   "A stochastic quasi-Newton method for large-scale optimization," 
%                   SIAM Journal on Optimization, 26(2), 1008-1031, 2016.
%
%       sub_mode:   SVRG-SQN:
%                   Philipp Moritz, Robert Nishihara, Michael I. Jordan,
%                   "A Linearly-Convergent Stochastic L-BFGS Algorithm," 
%                   Artificial Intelligence and Statistics (AISTATS), 2016.
%
%       sub_mode:   SVRG LBFGS:
%                   R. Kolte, M. Erdogdu and A. Ozgur, 
%                   "Accelerating SVRG via second-order information," 
%                   OPT2015, 2015.
%
%                   
% Created by H.Kasai on Oct. 15, 2016
% Modified by H.Kasai on Mar. 25, 2018


    % set dimensions and samples
    rng('shuffle')
    d = problem.dim();
    n = problem.samples();
    

    % set local options 
    local_options.sub_mode = 'SQN';  % SQN or SVRG-SQN or SVRG-LBFGS
    local_options.mem_size = 20;    
    
    % merge options
    options = mergeOptions(get_default_options(d), local_options);   
    options = mergeOptions(options, in_options);      
    
    % set paramters
    if options.batch_size > n
        options.batch_size = n;
    end   
    
    if ~isfield(in_options, 'batch_hess_size')
        options.batch_hess_size = 20 * options.batch_size;
    end    

    if options.batch_hess_size > n
        options.batch_hess_size = n;
    end    
    
    if strcmp(options.sub_mode, 'SQN') || strcmp(options.sub_mode, 'SVRG-SQN')
        if ~isfield(options, 'L')
            options.L = 20;
        else
            options.L = in_options.L;
        end   
    elseif strcmp(options.sub_mode, 'SVRG-LBFGS')
        options.L = Inf;
    end
        
    
    % initialize
    total_iter = 0;
    epoch = 0;
    grad_calc_count = 0;
    w = options.w_init;
    num_of_bachces = floor(n / options.batch_size);     
    
    s_array = [];
    y_array = [];    
    u_old = w;
    u_new = zeros(d,1);    

    % store first infos
    clear infos;    
    [infos, f_val, optgap] = store_infos(problem, w, options, [], epoch, grad_calc_count, 0);  
    
    % set start time
    start_time = tic();
    
    % display infos
    if options.verbose > 0
        fprintf('%s: Epoch = %03d, cost = %.16e, optgap = %.4e\n', options.sub_mode, epoch, f_val, optgap);
    end     

    % main loop
    step_test=[];
    angle_test=1;
    while (optgap > options.tol_optgap) && (epoch < options.max_epoch)

        % permute samples
        if options.permute_on
            perm_idx = randperm(n);
        else
            perm_idx = 1:n;
        end
        if(options.uo & epoch == 0)
            updateOrder=shuffle_wo_overlap(problem.N_scan,options.batch_size);
            num_of_bachces=length(updateOrder);
        end

        if strcmp(options.sub_mode, 'SVRG-SQN') || strcmp(options.sub_mode, 'SVRG-LBFGS')
            % compute full gradient
            %full_grad_new = problem.grad(w,1:n);
            full_grad_new = problem.full_grad(w);
            % count gradient evaluations
            grad_calc_count = grad_calc_count + n; 
        end          

        if strcmp(options.sub_mode, 'SVRG-LBFGS')
            if epoch > 0            
                % store cavature pair
                s_array = [s_array w - w0];
                y_array = [y_array full_grad_new - full_grad]; 

                % remove overflowed pair
                if(size(s_array,2)>options.mem_size)
                    s_array(:,1) = [];
                    y_array(:,1) = [];
                end     
            end
        end

        if strcmp(options.sub_mode, 'SVRG-SQN') || strcmp(options.sub_mode, 'SVRG-LBFGS')
            % store w for SVRG
            w0 = w;
            full_grad = full_grad_new;
        end          
      
        for j = 1 : num_of_bachces
            % indice_j_old=indice_j;
         
            % calculate gradient
            if(options.uo)
                indice_j = updateOrder{j};
            elseif(options.wr)
                indice_j = randi(n,1,options.batch_size);
            else
                start_index = (j-1) * options.batch_size + 1;
                indice_j = perm_idx(start_index:start_index+options.batch_size-1);
            end
            % [indice_jx,indice_jy]=ind2sub([sqrt(problem.N_scan),sqrt(problem.N_scan)],indice_j);
            % figure(10), plot(indice_jx,indice_jy,'r*');
            % pause;
            grad = problem.grad(w, indice_j);
            
            % calculate variance reduced gradient
            if strcmp(options.sub_mode, 'SVRG-SQN') || strcmp(options.sub_mode, 'SVRG-LBFGS')
                grad_w0 = problem.grad(w0,indice_j);
                grad = full_grad + grad - grad_w0;    
            end 
            
            % update step-size
            step = options.stepsizefun(total_iter, options);                

            if(epoch > 0)
                % perform LBFGS two loop recursion
                % Pw = problem.hess_diag(w,indice_j);
                Hg = lbfgs_two_loop_recursion(problem, grad, s_array, y_array,w);
                % update w            
                
                if(Hg'*grad > 0)
                    disp('not a descent direction, take steepest descent')
                    w = w - options.step_sd*grad;
                else
                    if strcmp(options.step_alg,'strong_wolfe')
                        c1 = 1e-4;
                        c2 = 0.9;
                        step = strong_wolfe_line_search(problem, Hg, w, c1, c2);
                    elseif strcmp(options.step_alg, 'backtracking')
                        rho = 1/2;
                        c = 1e-4;
                        step = backtracking_line_search(problem, Hg, w, rho, c,indice_j);%1:problem.samples);% 
                    end
                    w_old=w;
                    w = w + (step*Hg);  
                end
            else
                global H_init
                if(strcmp(H_init,'standard')); 
                    InvHess=1;
                else %if(strcmp(H_init,'probe_diag' ))
                    Pw = probe_weight(problem.probe,indice_j,problem.N,problem.ind_b);
                    % Pw = problem.hess_diag(w,indice_j);
                    % Pw= Pw./length(indice_j);
                    alpha=1e-2;
                    Pw = (1-alpha)*Pw+alpha*max(abs(problem.probe(:)).^2);
                    InvHess = 1./Pw;
                    InvHess(isinf(InvHess))=0;
                end
                % disp('steepest descent')
                w = w - (options.step_sd*InvHess.*grad); 
            end
            
            % proximal operator
            if ismethod(problem, 'prox')
                w = problem.prox(w, step);
            end              
            
            % calculate averaged w
            u_new = u_new + w/options.L;

            % update LBFGS vectors Hessian at every L iteration for 'SQN' or 'SVRG-SQN'
            % 'SVRG-LBFGS' does nothing because of L = Inf
            if(mod(total_iter,options.L)==0 && total_iter)                 
                
                % calcluate Hessian-vector product using subsamples
                %sub_indices = datasample((1:n), options.batch_hess_size);
                % "datasample" is supported only in statistics package in Octave. 
                % To avoid the packege, the following is an alternative. Modified by H.K. on Mar. 27, 2018.
                %%====original implementation
                if(options.batch_hess_size==options.batch_size)
                    sub_indices=indice_j;
                else
                  perm_sub_idx_hessian = randperm(n);
                  sub_indices = perm_sub_idx_hessian(1:options.batch_hess_size);
                end
                %%====with replacement
                % sub_indices = randi(n,1,options.batch_hess_size);
                
                % calculate hessian
                %H = problem.hess(w, sub_indices);
                %Hv = H*(u_new - u_old);
                % calculate hessian-vector product
                Hv = problem.hess_vec(u_new, u_new-u_old, sub_indices);
                %%=======================
                % g_new = problem.grad(u_new,sub_indices);
                % g_old = problem.grad(u_old,sub_indices);
                % Hv=g_new-g_old;
                %%==perform angle test
                angle_test=(u_new-u_old)'*Hv;
                if(angle_test>1e-8)
                    % store curvature pair
                    % 'y' curvature pair is calculated from a Hessian-vector product.
                    s_array = [s_array u_new - u_old];
                    y_array = [y_array Hv];%                 
                else
                    disp('skip curvature update')
                end
                
                % remove overflowed pair
                if(size(s_array,2)>options.mem_size)
                    s_array(:,1) = [];
                    y_array(:,1) = [];
                end                

                u_old = u_new;
                u_new = zeros(d,1);
                
                % count gradient evaluations
                % grad_calc_count = grad_calc_count + options.batch_hess_size;                
            end            
            total_iter = total_iter + 1;
            grad_calc_count = grad_calc_count + length(indice_j);        
        end
        
        % measure elapsed time
        elapsed_time = toc(start_time);
        
        % count gradient evaluations
        % grad_calc_count = grad_calc_count + j * options.batch_size;        
        epoch = epoch + 1;
        
        % store infos
        f_val_old=f_val;
        [infos, f_val, optgap] = store_infos(problem, w, options, infos, epoch, grad_calc_count, elapsed_time);            
        if(f_val_old<=f_val)
            disp('function increase')
            angle_test
        end

        % display infos
        if options.verbose > 0
            fprintf('%s: Epoch = %03d, cost = %.16e, optgap = %.4e\n', options.sub_mode, epoch, f_val, optgap);
        end
    end
    
    if optgap < options.tol_optgap
        fprintf('Optimality gap tolerance reached: tol_optgap = %g\n', options.tol_optgap);
    elseif epoch == options.max_epoch
        fprintf('Max epoch reached: max_epochr = %g\n', options.max_epoch);
    end      
end

