% Generated by ADiMat 0.5.9-4171
% Copyright 2009-2013 Johannes Willkomm, Fachgebiet Scientific Computing,
% TU Darmstadt, 64289 Darmstadt, Germany
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing,
% RWTH Aachen University, 52056 Aachen, Germany.
% Visit us on the web at http://www.adimat.de
% Report bugs to adimat-users@lists.sc.informatik.tu-darmstadt.de
%
%
%                             DISCLAIMER
%
% ADiMat was prepared as part of an employment at the Institute
% for Scientific Computing, RWTH Aachen University, Germany and is
% provided AS IS. NEITHER THE AUTHOR(S), THE GOVERNMENT OF THE FEDERAL
% REPUBLIC OF GERMANY NOR ANY AGENCY THEREOF, NOR THE RWTH AACHEN UNIVERSITY,
% INCLUDING ANY OF THEIR EMPLOYEES OR OFFICERS, MAKES ANY WARRANTY,
% EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL LIABILITY OR RESPONSIBILITY
% FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY INFORMATION OR
% PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE WOULD NOT INFRINGE
% PRIVATELY OWNED RIGHTS.
%
% Global flags were:
% FORWARDMODE -- Apply the forward mode to the files.
% NOOPEROPTIM -- Do not use optimized operators. I.e.:
%		 g_a*b*g_c -/-> mtimes3(g_a, b, g_c)
% NOLOCALCSE  -- Do not use local common subexpression elimination when
%		 canonicalizing the code.
% NOGLOBALCSE -- Prevents the application of global common subexpression
%		 elimination after canonicalizing the code.
% NOPRESCALARFOLDING -- Switch off folding of scalar constants before
%		 augmentation.
% NOPOSTSCALARFOLDING -- Switch off folding of scalar constants after
%		 augmentation.
% NOCONSTFOLDMULT0 -- Switch off folding of product with one factor
%		 being zero: b*0=0.
% FUNCMODE    -- Inputfile is a function (This flag can not be set explicitly).
% NOTMPCLEAR  -- Suppress generation of clear g_* instructions.
% UNBOUND_ERROR	-- Stop with error if unbound identifiers found (default).
% VERBOSITYLEVEL=4
% AD_IVARS= a, b
% AD_DVARS= z

% function z = adimat_sol_triu(a, b)
% 
% Solve upper triangular system a*x = b for x by backwards
% substitution, for automatic differentiation.
%
% Copyright 2013 Johannes Willkomm
%
function [g_z, z]= g_adimat_sol_triu(g_a, a, g_b, b)
   [m, n]= size(a); 
   assert(m== n); 
   z= zeros(m, size(b, 2)); 
   g_z= g_zeros(size(z));
   g_tmp_b_00000= g_b(n, : );
   tmp_b_00000= b(n, : );
   g_tmp_a_00000= g_a(n, n);
   tmp_a_00000= a(n, n);
   g_z(n, : )= (g_tmp_b_00000.* tmp_a_00000- tmp_b_00000.* g_tmp_a_00000)./ tmp_a_00000.^ 2;
   z(n, : )= tmp_b_00000./ tmp_a_00000; 
   for i= n- 1: -1: 1
      g_tmp_b_00001= g_b(i, : );
      tmp_b_00001= b(i, : );
      g_tmp_a_00001= g_a(i, i+ 1: end);
      tmp_a_00001= a(i, i+ 1: end);
      g_tmp_z_00000= g_z(i+ 1: end, : );
      tmp_z_00000= z(i+ 1: end, : );
      g_tmp_adimat_sol_triu_00000= g_tmp_a_00001* tmp_z_00000+ tmp_a_00001* g_tmp_z_00000;
      tmp_adimat_sol_triu_00000= tmp_a_00001* tmp_z_00000;
      g_tmp_adimat_sol_triu_00001= g_tmp_b_00001- g_tmp_adimat_sol_triu_00000;
      tmp_adimat_sol_triu_00001= tmp_b_00001- tmp_adimat_sol_triu_00000;
      g_tmp_a_00002= g_a(i, i);
      tmp_a_00002= a(i, i);
      g_z(i, : )= (g_tmp_adimat_sol_triu_00001.* tmp_a_00002- tmp_adimat_sol_triu_00001.* g_tmp_a_00002)./ tmp_a_00002.^ 2;
      z(i, : )= tmp_adimat_sol_triu_00001./ tmp_a_00002; 
   end
   % $Id: adimat_sol_triu.m 3935 2013-10-15 16:27:52Z willkomm $
