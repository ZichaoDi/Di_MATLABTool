function f=fdiffpow(x)
  [N popsi] = size(x); if N < 2 error('dimension must be greater one'); end

  f = sum(abs(x).^repmat(2+10*(0:N-1)'/(N-1), 1, popsi), 1);
  f = sqrt(f); 