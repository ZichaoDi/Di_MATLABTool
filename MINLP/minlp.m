% NONLINEAR MIXED INTEGER PROGRAM SOLVER
%   This program solves mixed integer problems with a branch and bound
%   method.
%
%   Further work:
%   Add heuristics to create a good initial integer solution
%   Add cuts to the problem (branch and cut method)
%
%   Some testing with the problem shows that it works well with up to 
%   around 30 integer variables and 10000 nlp variables.
%
% Version 1 - MILP by Thomas Trötscher 2009
% Version 2 - MINLP by John Hedengren 2012

% Results:
% x_best - best integer solution found
% f_best - best objective found

clear all
close all

tic;

addpath('apm')

% select server
%server = 'http://apmonitor.com';
%server = 'http://byu.apmonitor.com';
server = 'http://xps.apmonitor.com';

% application name
app = 'minlp';

% clear previous application
apm(server,app,'clear all');

% load model (can edit with text editor)
edit minlp.apm
apm_load(server,app,'minlp.apm');

%
% Local Options
%
o.display = 'iter';
% Algorithm display [iter,improve,final,off]
%
o.iterplot = true;
% Plot upper and lower bounds on objective function value while iterating
% [true,false]
%
o.solver = 1;
% NLP solver (1=apopt,2=bpopt,3=ipopt,etc)
%
o.Delta = 1e-8;
% Stopping tolerance of the gap (f_integer-f_lp)/(f_integer+f_lp)
%
o.maxNodes = 1e5;
% Maximum number of nodes in the branch and bound tree to visit
%
o.branchMethod = 3;
% 1 - depth first, 2 - breadth first, 3 - lowest cost, 4 - highest cost
%
o.branchCriteria = 1; 
% 1 - most fractional, 2 - least fractional, 3 - highest cost, 4 - lowest cost
%
o.intTol = 1e-6;
% Integer tolerance

apm_option(server,app,'nlc.solver',o.solver);
apm_option(server,app,'nlc.imode',3);

%Small test problem, optimal solution should be -21
lb = [0 0 0 0]';
ub = [1 1 1 1]';
yidx = true(4,1);
nx = size(lb,1);
for j = 1:nx,
    xi = ['x[' int2str(j) ']'];
    apm_info(server,app,'SV',xi);
end

%Assume no initial best integer solution
%Add your own heuristic here to find a good incumbent solution, store it in
%f_best,y_best,x_best
f_best = inf;
y_best = [];
x_best = [];

%Variable for holding the objective function variables of the lp-relaxation
%problems
f = inf(o.maxNodes,1);
f(1) = 0;
fs = inf;
numIntSol = double(~isempty(y_best));

%Set of problems
S = nan(sum(yidx),1);
D = zeros(sum(yidx),1);

%The priority in which the problems shall be solved
priority = [1];
%The indices of the problems that have been visited
visited = nan(o.maxNodes,1);

%Plot each iteration?
i=0;
if o.iterplot
    figure;
    hold on;
    title('Bounds')
    xlabel('Iteration')
    ylabel('Obj. fun. val')
end
%% Branch and bound loop
while i==0 || isinf(f_best) || (~isempty(priority) &&  ((f_best-min(fs(priority)))/abs(f_best+min(fs(priority))) > o.Delta) &&  i<o.maxNodes)
    %Is the parent node less expensive than the current best
    if i==0 || fs(priority(1))<f_best
        %Solve the LP-relaxation problem
        i=i+1;
        % s = vector of bound values (some may be NaN)
        % d = indication of
        %      >= lower (-1)
        %      <= upper (1)
        %      or no additional bound (0)
        s = S(:,priority(1));
        d = D(:,priority(1));

        new_lb = lb;
        new_ub = ub;
        for j = 1:nx,
            if(d(j)==-1),
                new_lb(j) = s(j);
            elseif(d(j)==1),
                new_ub(j) = s(j);
            end
        end
        
        for j = 1:nx,
            xl = ['x[' int2str(j) '].lower'];
            xu = ['x[' int2str(j) '].upper'];
            apm_option(server,app,xl,new_lb(j));
            apm_option(server,app,xu,new_ub(j));
        end
                
        apm(server,app,'solve')                        % solve
        sol = apm_sol(server,app);                     % retrieve solution
        x = cell2mat(sol(2,1:4))';                     % extract solution
        flag = apm_tag(server,app,'nlc.appstatus');    % successful solution
        this_f = apm_tag(server,app,'nlc.objfcnval');  % objective function
                
        %Visit this node
        visited(i) = priority(1);
        priority(1) = [];
        if flag~=1,
            %infeasible, dont branch
            disp('MINLP: Infeasible NLP problem or failed to converge.')
            f(i) = inf;
        else
            %convergence
            f(i) = this_f;  
            if this_f<f_best
                y = x(yidx);
                %fractional part of the integer variables -> diff
                diff = abs(round(y)-y);
                if all(diff<o.intTol)
                    %all fractions less than the integer tolerance
                    %we have integer solution
                    numIntSol = numIntSol+1;
                    f_best = this_f;
                    y_best = round(x(yidx));
                    x_best = x;
                else
                    if o.branchCriteria==1
                        %branch on the most fractional variable
                        [maxdiff,branch_idx] = max(diff,[],1);
                    elseif o.branchCriteria==2
                        %branch on the least fractional variable
                        diff(diff<o.intTol)=inf;
                        [mindiff,branch_idx] = min(diff,[],1);
                    elseif o.branchCriteria==3
                        %branch on the variable with highest cost
                        cy = c(yidx);
                        cy(diff<o.intTol)=-inf;
                        [maxcost,branch_idx] = max(cy,[],1);
                    elseif o.branchCriteria==4
                        %branch on the variable with lowest cost
                        cy = c(yidx);
                        cy(diff<o.intTol)=inf;
                        [mincost,branch_idx] = min(cy,[],1);  
                    else
                        error('MIPROG: Unknown branch criteria.')
                    end
                    %Branch into two subproblems
                    s1 = s;
                    s2 = s;
                    d1 = d;
                    d2 = d;
                    s1(branch_idx)=ceil(y(branch_idx));
                    d1(branch_idx)=-1; %direction of bound is GE
                    s2(branch_idx)=floor(y(branch_idx));
                    d2(branch_idx)=1; %direction of bound is LE
                    nsold = size(S,2);
                    
                    % add subproblems to the problem tree
                    S = [S s1 s2];
                    D = [D d1 d2];
                    fs = [fs f(i) f(i)];
                    
                    nsnew = nsold+2;

                    if o.branchMethod==1 || (o.branchMethod==13 && numIntSol<6)
                        %depth first, add newly branched problems to the
                        %beginning of the queue
                        priority = [nsold+1:nsnew priority];
                    elseif o.branchMethod==2
                        %breadth first, add newly branched problems to the
                        %end of the queue
                        priority = [priority nsold+1:nsnew];
                    elseif o.branchMethod==3 || (o.branchMethod==13 && numIntSol>=6)
                        %branch on the best lp solution
                        priority = [nsold+1:nsnew priority];
                        [dum,pidx] = sort(fs(priority));
                        priority=priority(pidx);
                    elseif o.branchMethod==4
                        %branch on the worst lp solution
                        priority = [nsold+1:nsnew priority];
                        [dum,pidx] = sort(-fs(priority));
                        priority=priority(pidx);
                    else
                        error('MINLP: Unknown branch method.')
                    end     
                end
            end
            if (strcmp(o.display,'improve') || strcmp(o.display,'iter')) && (f(i)==f_best || i==1) 
                disp(['It. ',num2str(i),'. Best integer solution: ',num2str(f_best),' Delta ',num2str(max([100*(f_best-min(fs(priority)))/abs(f_best+min(fs(priority))) 0 100*isinf(f_best)])),'%']);
                %disp(['Queue: ', num2str(length(priority))]);
            end
        end
        if strcmp(o.display,'iter')
            disp(['It. ',num2str(i),'. F-val(It): ',num2str(f(i)),' Delta ',num2str(max([100*(f_best-min(fs(priority)))/abs(f_best+min(fs(priority))) 0 100*isinf(f_best)])),'%. Queue len. ', num2str(length(priority))]);
        end
        if o.iterplot
            plot(i,[f_best min(fs(priority))],'x')
            if i==1
                legend('MINLP','NLP')
            end
            drawnow;
        end
    else %parent node is more expensive than current f-best -> don't evaluate this node
        priority(1) = [];
    end
end

% Summary
if ~strcmp(o.display,'off')
    disp(['Iteration ', num2str(sum(~isnan(visited))), '. Optimization ended.']);
    if isempty(priority) || f_best<min(fs(priority))
        disp('Found optimal solution!')
    elseif ~isinf(f_best)
        disp(['Ended optimization. Current delta ',num2str(max([100*(f_best-min(fs(priority)))/f_best 0 100*isinf(f_best)])),'%']);
    else
        disp(['Did not find any integer solutions']);
    end
    disp(['Time spent ', num2str(toc), ' seconds']);
    disp(['Objective function value: ',num2str(f_best)]);
end

% Recompute best solution
if (size(x_best,1)>=1),
   for j = 1:nx,
       xl = ['x[' int2str(j) '].lower'];
       xu = ['x[' int2str(j) '].upper'];
       apm_option(server,app,xl,x_best(j));
       apm_option(server,app,xu,x_best(j));
   end
end
apm(server,app,'solve')                        % solve
sol = apm_sol(server,app);                     % retrieve solution

% Open web-viewer to display best result
apm_var(server,app);

% Display final time
disp(['Time spent ', num2str(toc), ' seconds']);
