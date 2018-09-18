% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = permute(obj, order)
  obj.m_derivs = permute(obj.m_derivs, [1 order+1]);
  obj.m_size = obj.m_size(order);
end
% $Id: permute.m 4323 2014-05-23 09:17:16Z willkomm $
