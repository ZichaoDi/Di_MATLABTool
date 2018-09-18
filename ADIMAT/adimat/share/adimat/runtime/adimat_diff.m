% function [r] = adimat_diff2(x, n, dim)
%  
% Compute r = diff(x, n, dim), for AD.
%
% see also diff
%
% Copyright (C) 2014 Johannes Willkomm <johannes@johannes.willkomm.de>
%
function [z] = adimat_diff(x, n, dim)

  if nargin < 2
    n = 1;
  end
  if nargin < 3
    dim = adimat_first_nonsingleton(x);
  end
  
  assert(n == 1);
  
  sz = size(x);
  sz2 = sz;
  sz2(dim) = sz2(dim) - 1;
  
  ind = repmat({':'}, [length(sz), 1]);
  ind2 = ind;

  z = zeros(sz2) .* x(1);

  for i=2:sz(dim)
    ind{dim} = i-1;
    ind2{dim} = i;
    z(ind{:}) = x(ind2{:}) - x(ind{:});
  end

end

% $Id: adimat_norm2.m 4281 2014-05-21 09:23:04Z willkomm $

