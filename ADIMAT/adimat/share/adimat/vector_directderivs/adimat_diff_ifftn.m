function varargout = adimat_diff_ifftn(varargin)
   varargout{1} = [];
  varargout{1} = varargin{1};
  for dim=1:length(size(varargin{2}))
     if nargin < 3
       n = size(varargin{2}, dim);
     else
       n = varargin{3}(dim);
     end
     varargout{1} = ifft(varargout{1}, n, dim + 1);
  end
      ;
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
