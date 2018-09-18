function varargout = adimat_diff_qr(varargin)
  
        [varargout{2}  varargout{4}] = qr(varargin{2});
        [varargout{1}, ~, varargout{3}] = d_adimat_qr(varargin{1}, varargin{2});
      
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
