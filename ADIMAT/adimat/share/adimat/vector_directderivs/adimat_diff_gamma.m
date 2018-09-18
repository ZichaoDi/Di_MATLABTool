function varargout = adimat_diff_gamma(varargin)
   varargout{1} = (gamma(varargin{2}).*psi(varargin{2}).*varargin{1});
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
