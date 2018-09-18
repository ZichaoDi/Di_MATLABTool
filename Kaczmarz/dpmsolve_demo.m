%% An example of an direct projection method with preliminary full pivoting
% The direct projection method for solving linear systems with square matrix.
% It is assumed that the principal minors are nonsingular.
%
%% Author
% *Ivanov Andrey*, Candidate of Physico-Mathematical Sciences,
% *ssauivanov@gmail.com*.
%
% Dept. of Applied Mathematics, S. P. Korolyov Samara State Aerospace 
% University (National Research University), 
% Faculty of Computer Science, Samara, Russia
%
%% References
% [1]   Golub, G. H., & Van Loan, C. F. (2012). Matrix computations (Vol. 3). JHU Press.
%
% [2]   Gaussian Elimination using Complete Pivoting by Alvaro Moraes
%       http://www.mathworks.com/matlabcentral/fileexchange/25758-gaussian-elimination-using-complete-pivoting/content//GaElCoPi.m
%
% [3]   Zhdanov, A. I. (1997). Direct Sequence method for solving systems
%       of linear algebraic equations. Proceedings of the Russian Academy of Sciences.
%       (Vol. 356, No. 4, pp. 442-444).
%
% [4]   Benzi, M., & Meyer, C. D. (1995). A direct projection method for
%       sparse linear systems. SIAM Journal on Scientific Computing,
%       16(5), 1159-1176.
%
% [5]   Zhdanov, A. I., & Katsyuba, O. A. (1983). Consistency of least-square
%       estimates of parameters of linear difference equations with autocorrelation noise.
%       Cybernetics and Systems Analysis, 19(5), 716-725.
%
% [6]   Zhdanov, A. I., & Shamarov, P. A. (2000). A Direct Projection 
%       Method in the Problem of Complete Least Squares. 
%       AUTOMATION AND REMOTE CONTROL C/C OF AVTOMATIKA I TELEMEKHANIKA,
%       61(4; ISSU 1), 610-620.
%
% [7]   Benzi, M., Meyer, C. D., & Tuma, M. (1996). A sparse approximate
%       inverse preconditioner for the conjugate gradient method.
%       SIAM Journal on Scientific Computing, 17(5), 1135-1149.
%
%% Generate test problem
% It is a *very primitive example*. This is due to the fact that the
% pivoting algorithm and problem of find the permutation matrix
% is very complexes and must be solved concrete task.
%
n = 128;
E = eye(n,n);
A = E(n:-1:1,:);
[n,n] = size(A);
x_true = (1:1:n)';
b = A*x_true;

%% Generate permutation matrix with complete pivoting strategy
L=zeros(n); 
v=1:n; w=1:n;
for k=1:n-1
     [m,mc]=max(abs(A(v(k:n),w(k:n)))); 
     [m,c]=max(m);
     imc=c; imr=mc(c);
     imr=imr+k-1;
     imc=imc+k-1;
     v([k imr])=v([imr k]);
     w([k imc])=w([imc k]);
end
P=eye(n);P=P(v,:); 
Q=eye(n);Q=Q(:,w);

%% The process of solving the problem
% See more: *dpmsolve* description.
x = Q*dpmsolve(P*A*Q,P*b);
error=norm(x-x_true)/norm(x_true);

X = sprintf('The problem was solved with relative error: %d.',error);
disp(X)
