% function [a_a] = a_linsolve1(a_z, a, b, opts?)
%
% Compute adjoint of a in z = linsolve(a, b, opts), linear system
% solving.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013,2014 Johannes Willkomm
%
function [a_a] = a_linsolve1(a_z, a, b, varargin)
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
  
  if nargin > 3
    aopts = adimat_build_linsolve_adjopts(opts, a);
  else
    aopts = struct();
  end

  if broad
    if ~isreal(a)
      adj_sys = conj(a);
    else
      adj_sys = a;
    end
  
    z = linsolve(a, b, opts);
    rhs = -a_z * z.';
    a_a = call(@(x) linsolve(adj_sys, full(x), aopts), rhs);
    if isfield(opts, 'TRANSA') && opts.TRANSA
      a_a = a_a.';
    end
  else
    % z = pinv(a) * b;
    if isfield(opts, 'TRANSA') && opts.TRANSA
      a = a';
    end
    % if isfield(aopts, 'UT') && aopts.UT
    %   [a_a a_b z] = a_adimat_sol_triu(a, b, a_z);
    % elseif isfield(aopts, 'LT') && aopts.LT
    %   [a_a a_b z] = a_adimat_sol_tril(a, b, a_z);
    % else
    [a_a a_b z] = a_adimat_sol_qr(a, b, a_z);
    % end
    if isfield(opts, 'TRANSA') && opts.TRANSA
      a_a = a_a';
    end
  end
% $Id: a_linsolve1.m 4195 2014-05-14 18:01:25Z willkomm $
