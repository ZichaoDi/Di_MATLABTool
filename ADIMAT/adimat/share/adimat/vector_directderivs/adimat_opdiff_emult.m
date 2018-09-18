% function d_res = adimat_opdiff_emult(d_val1, val1, d_val2, val2)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_val1 = adimat_opdiff_emult(d_val1, val1, d_val2, val2)
  d_val1 = bsxfun(@times, d_val1, reshape(val2, [1 size(val2)])) + ...
           bsxfun(@times, reshape(val1, [1 size(val1)]), d_val2);

%$Id: adimat_opdiff_emult.m 4355 2014-05-28 11:10:28Z willkomm $
