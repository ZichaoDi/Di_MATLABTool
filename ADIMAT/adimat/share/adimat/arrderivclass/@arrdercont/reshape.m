% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = reshape(obj, varargin)
  epos = cellfun('isempty', varargin);
  if any(epos)
    eppos = find(epos);
    varargin{eppos} = prod(obj.m_size) ./ prod(cat(1, varargin{~epos}));
  end
  obj.m_size = [varargin{:}];
  obj.m_derivs = reshape(obj.m_derivs, [obj.m_ndd obj.m_size]);
end
% $Id: reshape.m 3862 2013-09-19 10:50:56Z willkomm $
