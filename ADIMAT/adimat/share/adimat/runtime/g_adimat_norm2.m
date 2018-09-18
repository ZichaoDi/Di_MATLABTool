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
% AD_IVARS= x
% AD_DVARS= r

% function [r] = adimat_norm2(x, p)
%  
% Compute r = norm(x, p), for AD.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt

function [g_r, r]= g_adimat_norm2(g_x, x, p)
   
   % r = norm(x, p);
   
   if ischar(p)
      if strcmp(lower(p), 'fro')
         g_tmp_x_00000= g_x(: );
         tmp_x_00000= x(: );
         g_tmp_x_00001= g_x(: );
         tmp_x_00001= x(: );
         g_tmp_conj_00000= call(@conj, g_tmp_x_00001);
         tmp_conj_00000= conj(tmp_x_00001);
         g_tmp_adimat_norm2_00000= g_tmp_x_00000.* tmp_conj_00000+ tmp_x_00000.* g_tmp_conj_00000;
         tmp_adimat_norm2_00000= tmp_x_00000.* tmp_conj_00000;
         g_tmp_sum_00000= call(@sum, g_tmp_adimat_norm2_00000);
         tmp_sum_00000= sum(tmp_adimat_norm2_00000);
         r= sqrt(tmp_sum_00000); 
         g_r= g_tmp_sum_00000./ (2.* r);
      else 
         error('Only "fro" is a valid string for p-norm computation currently.'); 
      end
   else 
      if isvector(x)
         if isinf(p)
            if p> 0
               [g_tmp_abs_00000, tmp_abs_00000]= g_abs(g_x, x);
               [r, tmp_max_00000]= max(tmp_abs_00000); 
               if numel(tmp_max_00000)== 1, 
                  g_r= g_tmp_abs_00000(tmp_max_00000); 
               else 
                  g_r= g_zeros(size(r)); 
                  for i= 1: numel(tmp_max_00000), 
                     g_r(i)= g_tmp_abs_00000(tmp_max_00000(i), i); 
                  end
               end; 
            else 
               [g_tmp_abs_00001, tmp_abs_00001]= g_abs(g_x, x);
               [r, tmp_min_00000]= min(tmp_abs_00001); 
               if numel(tmp_min_00000)== 1, 
                  g_r= g_tmp_abs_00001(tmp_min_00000); 
               else 
                  g_r= g_zeros(size(r)); 
                  for i= 1: numel(tmp_min_00000), 
                     g_r(i)= g_tmp_abs_00001(tmp_min_00000(i), i); 
                  end
               end; 
            end
         else 
            if isreal(x)&& mod(p, 2)== 0
               answer= admGetPref('pnormEven_p_useAbs'); 
               if strcmp(answer, 'yes')
                  [g_a, a]= g_abs(g_x, x); 
               else 
                  g_a= g_x;
                  a= x; 
               end
            else 
               [g_a, a]= g_abs(g_x, x); 
            end
            tmp_adimat_norm2_00004= p.* a.^ (p- 1);
            tmp_adimat_norm2_00004(a== 0& p== 0)= 0; % Ensure, that derivative of 0.^0 is 0 and not NaN.
            g_tmp_adimat_norm2_00001= tmp_adimat_norm2_00004.* g_a;
            tmp_adimat_norm2_00001= a.^ p;
            g_tmp_sum_00001= call(@sum, g_tmp_adimat_norm2_00001);
            tmp_sum_00001= sum(tmp_adimat_norm2_00001);
            tmp_adimat_norm2_00002= 1/ p;
            tmp_adimat_norm2_00005= tmp_adimat_norm2_00002.* tmp_sum_00001.^ (tmp_adimat_norm2_00002- 1);
            tmp_adimat_norm2_00005(tmp_sum_00001== 0& tmp_adimat_norm2_00002== 0)= 0; % Ensure, that derivative of 0.^0 is 0 and not NaN.
            g_r= tmp_adimat_norm2_00005.* g_tmp_sum_00001;
            r= tmp_sum_00001.^ tmp_adimat_norm2_00002; 
         end
      elseif ismatrix(x)
         if isinf(p)
            [g_a, a]= g_abs(g_x, x); 
            g_sa2= call(@sum, g_a, 2);
            sa2= sum(a, 2); 
            [r, tmp_max_00001]= max(sa2); 
            if numel(tmp_max_00001)== 1, 
               g_r= g_sa2(tmp_max_00001); 
            else 
               g_r= g_zeros(size(r)); 
               for i= 1: numel(tmp_max_00001), 
                  g_r(i)= g_sa2(tmp_max_00001(i), i); 
               end
            end; 
            %       case -inf
            % matlab does not support it, octave does the same as
            % for +inf...
            %        r = norm(x, inf);
         elseif p== 2%        if issparse(x)
            %          % FIXME: use svds!
            %          r = svds(x, 1);
            %        else
            if issparse(x)
               g_tmp_adimat_norm2_00003= call(@full, g_x);
               tmp_adimat_norm2_00003= full(x); 
               % Update detected: x= some_expression(x,...)
               g_x= g_tmp_adimat_norm2_00003;
               x= tmp_adimat_norm2_00003;
            end
            if isreal(x)
               [g_s, s]= adimat_g_svd(g_x, x); 
            else 
               [g_s, s]= g_adimat_svd(g_x, x); 
            end
            [r, tmp_max_00002]= max(s); 
            if numel(tmp_max_00002)== 1, 
               g_r= g_s(tmp_max_00002); 
            else 
               g_r= g_zeros(size(r)); 
               for i= 1: numel(tmp_max_00002), 
                  g_r(i)= g_s(tmp_max_00002(i), i); 
               end
            end; 
            %        end
         elseif p== 1
            [g_a, a]= g_abs(g_x, x); 
            g_sa2= call(@sum, g_a, 1);
            sa2= sum(a, 1); 
            [r, tmp_max_00003]= max(sa2); 
            if numel(tmp_max_00003)== 1, 
               g_r= g_sa2(tmp_max_00003); 
            else 
               g_r= g_zeros(size(r)); 
               for i= 1: numel(tmp_max_00003), 
                  g_r(i)= g_sa2(tmp_max_00003(i), i); 
               end
            end; 
         else 
            error('Derivatives of matrix-p-norm not implemented yet.'); 
         end
      end
   end
   
end

% $Id: adimat_norm2.m 3956 2013-10-23 08:43:36Z willkomm $

