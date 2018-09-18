function varargout = adimat_diff_cell2mat(varargin)
   varargout{1} = call(@cell2mat, varargin{1});
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
