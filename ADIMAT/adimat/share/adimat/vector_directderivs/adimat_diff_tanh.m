function varargout = adimat_diff_tanh(varargin)
  [varargout{1} varargout{2}] = adimat_fdiff_vunary(varargin{1}, varargin{2}, @dpartial_tanh);
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
