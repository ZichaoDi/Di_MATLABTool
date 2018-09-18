function obj = diag(obj, varargin)
  obj = unopLoop(obj, @diag, varargin{:});
