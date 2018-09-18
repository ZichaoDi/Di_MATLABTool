function res= call(func, g, varargin)
%CALL Call func with one derivative and optional parameters.
%
% call(@f, g, varargin) expects g to be a derivative object, violation of this
% rule results in incorrect results.
%
% Copyright 2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

% Ensure, that func is a function handle and not a string.
if ~ isa(func, 'function_handle')
   func= str2fun(func);
end

if nargin>2
  res= func(g, varargin{:});
else
  res= func(g);
end


