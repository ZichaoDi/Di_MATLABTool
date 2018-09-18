% function d_res = adimat_opdiff_ediv_left(val1, d_val2, val2)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_val2 = adimat_opdiff_ediv_left(val1, d_val2, val2)
  factor = -val1 ./ (val2 .^ 2);
  d_val2 = bsxfun(@times, reshape(factor, [1 size(factor)]), d_val2);
end
% $Id: adimat_opdiff_ediv_left.m 4355 2014-05-28 11:10:28Z willkomm $
