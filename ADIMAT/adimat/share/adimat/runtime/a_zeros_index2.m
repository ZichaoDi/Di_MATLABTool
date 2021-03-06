% function r = a_zeros_index2(adjArrayVar, arrayVar, index1, index2)
%   Zero adjoint of index expression after assignment. If the forward
%   assignment changed the size of the array variable, then maybe
%   resize the adjoint here, undoing the size change.  If the size did
%   not change then fill the indexed adjoint with a_zeros.
%
% see also a_zeros, adimat_push_index, adimat_pop_index
%
% This file is part of the ADiMat runtime environment
%
function adj = a_zeros_index2(adj, arrayVar, ind1, ind2)
  szAdj = size(adj);
  szVar = size(arrayVar);
  if isequal(szAdj, szVar)
    adj(ind1, ind2) = a_zeros(arrayVar(ind1, ind2));
  else
    test2 = zeros(szVar);
    test2(ind1, ind2) = 1;
    test3 = ones(szVar);
    topIndex = num2cell(szAdj);
    test3(topIndex{:}) = 0;
    selwrit = test2 == 1;
    selold = test3 == 1;
    adj(selwrit) = a_zeros(adj(selwrit));
    adj = reshape(adj(selold), szVar);
  end
% $Id: a_zeros_index2.m 3294 2012-05-30 11:30:18Z willkomm $
