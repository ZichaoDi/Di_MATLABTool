function varargout = adimat_diff_mat2cell(varargin)
   varargout{1} = call(@mat2cell, varargin{1}, varargin{3:end});
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
