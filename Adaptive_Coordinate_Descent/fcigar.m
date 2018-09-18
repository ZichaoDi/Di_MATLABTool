function f=cigar(x, ar)
  if nargin < 2 || isempty(ar)
    ar = 1e3;
  end
  f = x(1,:).^2 + ar^2*sum(x(2:end,:).^2,1);
