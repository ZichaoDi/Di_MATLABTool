function varargout = adimat_diff_squeeze(varargin)

      varargout{2} = squeeze(varargin{2});
      varargout{1} = reshape(varargin{1}, [size(varargin{1}, 1) size(varargout{2})]);
      
end
% automatically generated from $Id: derivatives-vdd.xml 3983 2013-12-21 11:20:23Z willkomm $
