% Generated by ADiMat 0.5.9-4171
% © 2001-2008 Andre Vehreschild <vehreschild@sc.rwth-aachen.de>
% © 2009-2013 Johannes Willkomm <johannes.willkomm@sc.tu-darmstadt.de>
% RWTH Aachen University, 52056 Aachen, Germany
% TU Darmstadt, 64289 Darmstadt, Germany
% Visit us on the web at http://www.sc.informatik.tu-darmstadt.de/res/adimat/
% Report bugs to adimat-users@lists.sc.informatik.tu-darmstadt.de
%
%                             DISCLAIMER
% 
% ADiMat was prepared as part of an employment at the Institute for Scientific Computing,
% RWTH Aachen University, Germany and at the Institute for Scientific Computing,
% TU Darmstadt, Germany and is provided AS IS. 
% NEITHER THE AUTHOR(S), THE GOVERNMENT OF THE FEDERAL REPUBLIC OF GERMANY
% NOR ANY AGENCY THEREOF, NOR THE RWTH AACHEN UNIVERSITY, NOT THE TU DARMSTADT,
% INCLUDING ANY OF THEIR EMPLOYEES OR OFFICERS, MAKES ANY WARRANTY, EXPRESS OR IMPLIED,
% OR ASSUMES ANY LEGAL LIABILITY OR RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS,
% OR USEFULNESS OF ANY INFORMATION OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE
% WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
%
% Flags: BACKWARDMODE,  NOOPEROPTIM,
%   NOLOCALCSE,  NOGLOBALCSE,  NOPRESCALARFOLDING,
%   NOPOSTSCALARFOLDING,  NOCONSTFOLDMULT0,  FUNCMODE,
%   NOTMPCLEAR,  DUMP_XML,  PARSE_ONLY,
%   UNBOUND_ERROR
%
% Parameters:
%  - dependents=z
%  - independents=a, b
%  - inputEncoding=ISO-8859-1
%  - output-mode: plain
%  - output-file: ad_out/a_adimat_sol_tril.m
%  - output-file-prefix: 
%  - output-directory: ad_out
%
% Functions in this file: a_adimat_sol_tril, rec_adimat_sol_tril,
%  ret_adimat_sol_tril
%

function [a_a a_b nr_z] = a_adimat_sol_tril(a, b, a_z)
   tmpda4 = 0;
   tmpda3 = 0;
   tmpca2 = 0;
   tmpca1 = 0;
   [m n] = size(a);
   assert(m == n);
   tmpda1 = size(b, 2);
   z = zeros(m, tmpda1);
   tmplia1 = b(1, :) ./ a(1, 1);
   adimat_push_index(z, 1, ':');
   z(1, :) = tmplia1;
   tmpfra1_2 = n;
   for i=2 : tmpfra1_2
      adimat_push(tmpda4);
      tmpda4 = i - 1;
      adimat_push(tmpda3);
      tmpda3 = i - 1;
      adimat_push(tmpca2);
      tmpca2 = a(i, 1 : tmpda3) * z(1 : tmpda4, :);
      adimat_push(tmpca1);
      tmpca1 = b(i, :) - tmpca2;
      adimat_push(tmplia1);
      tmplia1 = tmpca1 ./ a(i, i);
      adimat_push_index(z, i, ':');
      z(i, :) = tmplia1;
   end
   adimat_push(tmpfra1_2);
   nr_z = z;
   [a_tmplia1 a_tmpca2 a_tmpca1 a_a a_b] = a_zeros(tmplia1, tmpca2, tmpca1, a, b);
   if nargin < 3
      a_z = a_zeros(z);
   end
   tmpfra1_2 = adimat_pop;
   for i=fliplr(2 : tmpfra1_2)
      z = adimat_pop_index(z, i, ':');
      a_tmplia1 = adimat_adjsum(a_tmplia1, adimat_adjred(tmplia1, adimat_adjreshape(tmplia1, a_z(i, :))));
      a_z = a_zeros_index(a_z, z, i, ':');
      tmplia1 = adimat_pop;
      a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, a_tmplia1 ./ a(i, i)));
      a_a(i, i) = adimat_adjsum(a_a(i, i), adimat_adjred(a(i, i), -((tmpca1./a(i, i) .* a_tmplia1) ./ a(i, i))));
      a_tmplia1 = a_zeros(tmplia1);
      tmpca1 = adimat_pop;
      a_b(i, :) = adimat_adjsum(a_b(i, :), adimat_adjred(b(i, :), a_tmpca1));
      a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, -a_tmpca1));
      a_tmpca1 = a_zeros(tmpca1);
      tmpca2 = adimat_pop;
      a_a(i, 1 : tmpda3) = adimat_adjsum(a_a(i, 1 : tmpda3), adimat_adjmultl(a(i, 1 : tmpda3), a_tmpca2, z(1 : tmpda4, :)));
      a_z(1 : tmpda4, :) = adimat_adjsum(a_z(1 : tmpda4, :), adimat_adjmultr(z(1 : tmpda4, :), a(i, 1 : tmpda3), a_tmpca2));
      a_tmpca2 = a_zeros(tmpca2);
      [tmpda3 tmpda4] = adimat_pop;
   end
   z = adimat_pop_index(z, 1, ':');
   a_tmplia1 = adimat_adjsum(a_tmplia1, adimat_adjred(tmplia1, adimat_adjreshape(tmplia1, a_z(1, :))));
   a_z = a_zeros_index(a_z, z, 1, ':');
   a_b(1, :) = adimat_adjsum(a_b(1, :), adimat_adjred(b(1, :), a_tmplia1 ./ a(1, 1)));
   a_a(1, 1) = adimat_adjsum(a_a(1, 1), adimat_adjred(a(1, 1), -((b(1, :)./a(1, 1) .* a_tmplia1) ./ a(1, 1))));
   assert(m == n);
end

function z = rec_adimat_sol_tril(a, b)
   tmpda4 = 0;
   tmpda3 = 0;
   tmpca2 = 0;
   tmpca1 = 0;
   [m n] = size(a);
   assert(m == n);
   tmpda1 = size(b, 2);
   z = zeros(m, tmpda1);
   tmplia1 = b(1, :) ./ a(1, 1);
   adimat_push_index(z, 1, ':');
   z(1, :) = tmplia1;
   tmpfra1_2 = n;
   for i=2 : tmpfra1_2
      adimat_push(tmpda4);
      tmpda4 = i - 1;
      adimat_push(tmpda3);
      tmpda3 = i - 1;
      adimat_push(tmpca2);
      tmpca2 = a(i, 1 : tmpda3) * z(1 : tmpda4, :);
      adimat_push(tmpca1);
      tmpca1 = b(i, :) - tmpca2;
      adimat_push(tmplia1);
      tmplia1 = tmpca1 ./ a(i, i);
      adimat_push_index(z, i, ':');
      z(i, :) = tmplia1;
   end
   adimat_push(tmpfra1_2, m, n, tmpda1, tmplia1, tmpda4, tmpda3, tmpca2, tmpca1, z, a, b);
end

function [a_a a_b] = ret_adimat_sol_tril(a_z)
   [b a z tmpca1 tmpca2 tmpda3 tmpda4 tmplia1 tmpda1 n m] = adimat_pop;
   [a_tmplia1 a_tmpca2 a_tmpca1 a_a a_b] = a_zeros(tmplia1, tmpca2, tmpca1, a, b);
   if nargin < 1
      a_z = a_zeros(z);
   end
   tmpfra1_2 = adimat_pop;
   for i=fliplr(2 : tmpfra1_2)
      z = adimat_pop_index(z, i, ':');
      a_tmplia1 = adimat_adjsum(a_tmplia1, adimat_adjred(tmplia1, adimat_adjreshape(tmplia1, a_z(i, :))));
      a_z = a_zeros_index(a_z, z, i, ':');
      tmplia1 = adimat_pop;
      a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, a_tmplia1 ./ a(i, i)));
      a_a(i, i) = adimat_adjsum(a_a(i, i), adimat_adjred(a(i, i), -((tmpca1./a(i, i) .* a_tmplia1) ./ a(i, i))));
      a_tmplia1 = a_zeros(tmplia1);
      tmpca1 = adimat_pop;
      a_b(i, :) = adimat_adjsum(a_b(i, :), adimat_adjred(b(i, :), a_tmpca1));
      a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, -a_tmpca1));
      a_tmpca1 = a_zeros(tmpca1);
      tmpca2 = adimat_pop;
      a_a(i, 1 : tmpda3) = adimat_adjsum(a_a(i, 1 : tmpda3), adimat_adjmultl(a(i, 1 : tmpda3), a_tmpca2, z(1 : tmpda4, :)));
      a_z(1 : tmpda4, :) = adimat_adjsum(a_z(1 : tmpda4, :), adimat_adjmultr(z(1 : tmpda4, :), a(i, 1 : tmpda3), a_tmpca2));
      a_tmpca2 = a_zeros(tmpca2);
      [tmpda3 tmpda4] = adimat_pop;
   end
   z = adimat_pop_index(z, 1, ':');
   a_tmplia1 = adimat_adjsum(a_tmplia1, adimat_adjred(tmplia1, adimat_adjreshape(tmplia1, a_z(1, :))));
   a_z = a_zeros_index(a_z, z, 1, ':');
   a_b(1, :) = adimat_adjsum(a_b(1, :), adimat_adjred(b(1, :), a_tmplia1 ./ a(1, 1)));
   a_a(1, 1) = adimat_adjsum(a_a(1, 1), adimat_adjred(a(1, 1), -((b(1, :)./a(1, 1) .* a_tmplia1) ./ a(1, 1))));
   assert(m == n);
end
