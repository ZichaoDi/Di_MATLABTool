% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = mean(obj, k)
  if nargin < 2
    k = adimat_first_nonsingleton(obj);
  end
  obj.m_derivs = mean(obj.m_derivs, k+1);
  obj.m_size = computeSize(obj);
end
% $Id: mean.m 4323 2014-05-23 09:17:16Z willkomm $
