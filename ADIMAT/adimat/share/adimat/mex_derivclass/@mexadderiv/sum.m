function res=sum(g, dim)
%MEXADDERIV/SUM Compute sum on the derivative object.
%
%  see also sum, createFullGradients, g_zeros
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!
%
  
  sz = get(g, 'size');
  % FIXME: remove assertion after migration from ObjSize to size
  if ~isequal(sz, size(g))
    error('adimat:mex_derivclass:sum', '%s', 'size is wrong');
  end
  ndim = length(sz);
  
  res = g;

  if sz(1) == 1 && sz(2) == 1 && ndim == 2
  elseif prod(sz) == 0
    error('adimat:mex_derivclass:sum', '%s', 'dimensions are zero');
  else
    
    if nargin < 2
      [cols, rows] = find(sz > 1);
      firstNonSingleton = rows(1);
      dim = firstNonSingleton;
    end
      
    for i=1:length(g.deriv)
      res.deriv{i} = sum(g.deriv{i}, dim);
    end
  end
end
