function Tc=imtranslate2D(T,w)
omega = [0,size(T,1),0,size(T,2)];

m   = size(T);   
x = getCellCenteredGrid(omega,m);  
%%========================================================
% yc = translation2D(w,x);
n = length(x)/2;
Q = sparse(kron(speye(2),ones(n,1)));
y  = x + Q*w;
clear Q;
%%=========================================================
% Tc = linearInter(T,omega,x);

dim = length(omega)/2;
n   = length(y)/dim;
y   = reshape(y,n,dim);
h   = (omega(2:2:end)-omega(1:2:end))./m;


% map x from [h/2,omega-h/2] -> [1,m],
for i=1:dim, y(:,i) = (y(:,i)-omega(2*i-1))/h(i) + 0.5; end;

Valid = @(j) (0<y(:,j) & y(:,j)<m(j)+1);      % determine indices of valid points
Tc = zeros(n,1); % initialize output
% Tc = ones(n,1); % initialize output
pad = 1; TP = pad*ones(m+2*pad);                 % pad data to reduce cases

P = floor(y); y = y-P;                        % split x into integer/remainder
valid = find( Valid(1) & Valid(2) );
p = @(j) P(valid,j); xi = @(j) y(valid,j);

% increments for linearized ordering
i1 = 1; i2 = size(T,1)+2*pad; i3 = (size(T,1)+2*pad)*(size(T,2)+2*pad);
TP(pad+(1:m(1)),pad+(1:m(2))) = T;
% clear T;
p  = (pad + p(1)) + i2*(pad + p(2) - 1);
% compute Tc as weighted sum
Tc(valid) = (TP(p)   .* (1-xi(1)) + TP(p+i1)    .*xi(1)) .* (1-xi(2)) ...
  + (TP(p+i2) .* (1-xi(1)) + TP(p+i1+i2) .*xi(1)) .* (xi(2));
clear x y
Tc=reshape(Tc,m);
