% function [a_b] = a_linsolve2(a_z, a, b, varargin)
%
% Compute adjoint of b in z = linsolve(a, b, opts), linear system
% solving.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013,2014 Johannes Willkomm
%
function [a_b] = a_linsolve2(a_z, a, b, varargin)
  [m n] = size(a);

  opts = struct;
  if nargin > 3
    opts = varargin{1};
  end
  if isfield(opts, 'TRANSA') && opts.TRANSA
    broad = m >= n;
  else
    broad = m <= n;
  end
  
  if broad
    if ~isreal(a)
      adj_sys = conj(a);
    else
      adj_sys = a;
    end
  
    if nargin > 3
      opts = varargin{1};
      aopts = adimat_build_linsolve_adjopts(opts, a);
    else
      aopts = struct();
    end

    a_b = call(@(x) linsolve(adj_sys, full(x), aopts), a_z);
  
  else
  
    [a_a a_b z] = a_adimat_sol_qr(a, b, a_z);
  
  end
  

% $Id: a_linsolve2.m 4195 2014-05-14 18:01:25Z willkomm $
  