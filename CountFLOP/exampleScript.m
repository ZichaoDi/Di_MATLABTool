
% This is just a test of FLOPS counting

% Matrix dimensions
m = 3;
n = 4;
k = 5;

% Matrix generation
A = rand(m,n);
B = ones(m,n);
C = randn(n,k) <= 0.5;

% Test plus, minus, multiplication and division
D = A + B;
E = A * C;
F = ((A .* (A + B)) ./ (A-B)) * C;
G = bsxfun(@minus,A,mean(A));

% Test linear algebra
P = rand(m);
PP = P * P';
P = chol(P*P');
[L,U] = lu(P);
[Q,R] = qr(P);
P = inv(P);
x = P \ rand(m,1);

% Test statistics and math function
for r = 1:m
    S = sum(A);
    S = sin(A+2*B);
end

% Test user supplied rules
R = mod(randi(100,m,n), randi(100,m,n));
g = gamma(A);

% Save all variables in a MAT file for FLOPS counting
save exampleScriptMAT




