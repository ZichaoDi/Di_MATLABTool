function varargout = adimat_diff_cumsum1(varargin)
   varargout{1} = cumsum(varargin{1}, adimat_first_nonsingleton(varargin{2}) + 1);
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
