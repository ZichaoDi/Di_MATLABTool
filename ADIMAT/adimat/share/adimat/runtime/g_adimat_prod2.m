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
% AD_IVARS= a
% AD_DVARS= z

function [g_z, z]= g_adimat_prod2(g_a, a, dim)
   
   sz= size(a); 
   
   ind= repmat({':'}, [length(sz), 1]); 
   ind{dim}= 1; 
   
   g_tmp_a_00000= g_a(ind{: });
   tmp_a_00000= a(ind{: });
   g_z= g_tmp_a_00000;
   z= tmp_a_00000; 
   for i= 2: sz(dim)
      ind{dim}= i; 
      g_tmp_a_00001= g_a(ind{: });
      tmp_a_00001= a(ind{: });
      g_tmp_adimat_prod2_00000= g_z.* tmp_a_00001+ z.* g_tmp_a_00001;
      tmp_adimat_prod2_00000= z.* tmp_a_00001; 
      % Update detected: z= some_expression(z,...)
      g_z= g_tmp_adimat_prod2_00000;
      z= tmp_adimat_prod2_00000;
   end
   
   % $Id: adimat_prod2.m 3821 2013-07-16 08:55:22Z willkomm $
