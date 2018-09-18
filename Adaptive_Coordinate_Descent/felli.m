
function f=felli(x)
%  f = rand();
%  return;
  N = size(x,1); if N < 2 error('dimension must be greater one'); end
  f=1e6.^((0:N-1)/(N-1)) * x.^2;
end