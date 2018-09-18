function [ u ] = dpmsolve( A,f,u0)
global ws N2 Ntot
%DPMSOLVE The direct projection method for solving linear systems with square matrix (without pivoting)
%   It is assumed that the main minors are nonsingular.
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
% [1]   Zhdanov, A. I. (1997). Direct Sequence method for solving systems
%       of linear algebraic equations. Proceedings of the Russian Academy of Sciences.
%       (Vol. 356, No. 4, pp. 442-444).
% [2]   Benzi, M., & Meyer, C. D. (1995). A direct projection method for
%       sparse linear systems. SIAM Journal on Scientific Computing,
%       16(5), 1159-1176.
% [3]   Zhdanov, A. I., & Katsyuba, O. A. (1983). Consistency of least-square
%       estimates of parameters of linear difference equations with autocorrelation noise.
%       Cybernetics and Systems Analysis, 19(5), 716-725.
% [4]   Zhdanov, A. I., & Shamarov, P. A. (2000). A Direct Projection 
%       Method in the Problem of Complete Least Squares. 
%       AUTOMATION AND REMOTE CONTROL C/C OF AVTOMATIKA I TELEMEKHANIKA,
%       61(4; ISSU 1), 610-620.
% [5]   Benzi, M., Meyer, C. D., & Tuma, M. (1996). A sparse approximate
%       inverse preconditioner for the conjugate gradient method.
%       SIAM Journal on Scientific Computing, 17(5), 1135-1149.

if nargin < 2
    error('Too few input arguments')
end

[m,n] = size(A);

% The matrix A must be square.
if n ~= m
    error('Matrix must be square')
end

% The sizes of A, f must match.
if size(f,1) ~= m || size(f,2) ~= 1
    error('The size of A and b do not match')
end

u = u0;%zeros(n,1);
P = eye(n);
err=[];
res=[];
sing_rec=[];
for j = 1:1:n-1
    res(j)=norm(f-A*u);
    err(j)=norm(ws-u);
    sing_rec(j,:)=[j,norm(f-A*u),norm(ws-u)];
    fprintf('%d       %e       %e\n',sing_rec(j,:));
    plotIter=0;
    if(n==N2(1)& plotIter)
        figure(3);
        subplot(1,2,1),plot(j+Ntot(1),res(j),'b*-');hold on; drawnow;
        title(['Iteration #:',num2str(j+Ntot(1)),' Residual']);
        subplot(1,2,2),plot(j+Ntot(1),err(j),'r.-');hold on;drawnow;
        title('Error')
        figure(4);subplot(1,2,1),surf(reshape(ws-u,sqrt(N2(1)),sqrt(N2(1))));
        subplot(1,2,2),plot(f-A*u,'r.-')
    end
    delta = A(j,1:j)*P(1:j,j);
    if  abs(delta) < eps
        error('Error: use reordering or pivoting for correct calculation');
    end;
    u(1:j) = u(1:j) + P(1:j, j)*((f(j)-A(j,1:j)*u(1:j)) / delta);
    P(1:j,j+1:end) = P(1:j,j+1:end) - (P(1:j,j)/ delta)*(A(j,:)*P(:,j+1:end)) ;
    P(1:j,j) = 0;
end;

delta = A(n,:)*P(:,n);
u = u + P(:,n)*( f(n)-A(n,:)*u ) / delta;

end

