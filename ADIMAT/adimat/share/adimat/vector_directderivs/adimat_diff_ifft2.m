function varargout = adimat_diff_ifft2(varargin)
   varargout{1} = [];
  if nargin < 3
    m = size(varargin{2}, 1);
  else
    m = varargin{3};
  end
  if nargin < 4
    n = size(varargin{2}, 2);
  else
    n = varargin{4};
  end
  varargout{1} = ifft(varargin{1}, m, 2);
  varargout{1} = ifft(varargout{1}, n, 3);
      ;
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
