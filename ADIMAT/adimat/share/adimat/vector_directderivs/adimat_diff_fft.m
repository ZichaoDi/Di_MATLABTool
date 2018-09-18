function varargout = adimat_diff_fft(varargin)
   varargout{1} = [];
  if nargin < 4
    if isscalar(varargin{2})
      dim = 2; 
    else
      dim = adimat_first_nonsingleton(varargin{2});
    end
  else
    dim = varargin{4};
  end
  if nargin < 3
    n = size(varargin{2}, dim);
  else
    n = varargin{3};
  end
  varargout{1} = fft(varargin{1}, n, dim + 1);
      ;
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
