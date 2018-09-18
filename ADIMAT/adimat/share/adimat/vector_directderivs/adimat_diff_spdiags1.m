function varargout = adimat_diff_spdiags1(varargin)
   varargout{1} = call(@spdiags, varargin{1}, varargin{3});
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
