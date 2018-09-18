function varargout = adimat_diff_circshift(varargin)
   varargout{1} = circshift(varargin{1}, [0; varargin{3}(:)]);
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
