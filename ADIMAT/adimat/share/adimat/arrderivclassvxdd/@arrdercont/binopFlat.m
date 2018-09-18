% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlat(obj, right, handle)
  if isobject(obj)
    isc_obj = prod(obj.m_size) == 1;
    dd1 = reshape(obj.m_derivs, [obj.m_size obj.m_ndd]);
    if isobject(right)
      dd2 = reshape(right.m_derivs, [right.m_size right.m_ndd]);
      if isc_obj
        obj.m_size = right.m_size;
      end
    else
      dd2 = right;
      if isc_obj
        obj.m_size = size(right);
      end
    end
  else
    dd1 = obj;
    dd2 = reshape(right.m_derivs, [right.m_size right.m_ndd]);
    isc_right = prod(right.m_size) == 1;
    if isc_right
      right.m_size = size(obj);
      if length(right.m_size) > 2
        dd2 = reshape(dd2, [ones(1, length(right.m_size)) right.m_ndd]);
      end
    end
    obj = right;
  end
  obj.m_derivs = shiftedbsx(handle, dd1, dd2);
  obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size), obj.m_ndd]);
end
% $Id: binopFlat.m 4469 2014-06-11 19:12:43Z willkomm $
