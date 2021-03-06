% Generated by ADiMat 0.5.9-3862
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
%  - dependents=Q, H
%  - independents=A
%  - inputEncoding=ISO-8859-1
%  - output-mode: plain
%  - output-file: ad_out/a_adimat_hess_11.m
%  - output-file-prefix: 
%  - output-directory: ad_out
%
% Functions in this file: a_adimat_hess, rec_adimat_hess,
%  ret_adimat_hess, a_mk_householder_elim, rec_mk_householder_elim,
%  ret_mk_householder_elim, a_mk_householder_elim_vec_lapack, rec_mk_householder_elim_vec_lapack,
%  ret_mk_householder_elim_vec_lapack
%

function [a_A nr_Q nr_H] = a_adimat_hess(A, a_Q, a_H)
   tmpca1 = 0;
   tmpca2 = 0;
   tmpca4 = 0;
   tmpca3 = 0;
   Pk = 0;
   n = size(A, 1);
   Q = eye(n);
   H = A;
   tmpfra1_2 = n - 1;
   for k=1 : tmpfra1_2
      adimat_push(Pk);
      Pk = rec_mk_householder_elim(H, k + 1, k);
      adimat_push(Q);
      Q = Q * Pk;
      adimat_push(tmpca1);
      tmpca1 = Pk' * H;
      adimat_push(H);
      H = tmpca1 * Pk;
   end
   adimat_push(tmpfra1_2);
   tmpba1 = 0;
   if adimat_issymmetric(H)
      tmpba1 = 1;
      adimat_push(tmpca2);
      tmpca2 = real(H);
      adimat_push(tmpca1);
      tmpca1 = triu(tmpca2, -1);
      adimat_push(H);
      H = tril(tmpca1, 1);
   else
      adimat_push(tmpca4);
      tmpca4 = tril(H, -1);
      adimat_push(tmpca3);
      tmpca3 = triu(tmpca4, -1);
      adimat_push(tmpca2);
      tmpca2 = real(tmpca3);
      adimat_push(tmpca1);
      tmpca1 = triu(H);
      adimat_push(H);
      H = tmpca1 + tmpca2;
   end
   adimat_push(tmpba1);
   nr_Q = Q;
   nr_H = H;
   [a_Pk a_tmpca1 a_tmpca2 a_tmpca4 a_tmpca3 a_A] = a_zeros(Pk, tmpca1, tmpca2, tmpca4, tmpca3, A);
   if nargin < 2
      a_Q = a_zeros(Q);
   end
   if nargin < 3
      a_H = a_zeros(H);
   end
   tmpba1 = adimat_pop;
   if tmpba1 == 1
      H = adimat_pop;
      a_tmpca1 = a_tmpca1 + call(@tril, a_H, 1);
      a_H = a_zeros(H);
      tmpca1 = adimat_pop;
      a_tmpca2 = a_tmpca2 + call(@triu, a_tmpca1, -1);
      a_tmpca1 = a_zeros(tmpca1);
      tmpca2 = adimat_pop;
      a_H = a_H + call(@real, a_tmpca2);
      a_tmpca2 = a_zeros(tmpca2);
   else
      H = adimat_pop;
      a_tmpca1 = a_tmpca1 + adimat_adjred(tmpca1, a_H);
      a_tmpca2 = a_tmpca2 + adimat_adjred(tmpca2, a_H);
      a_H = a_zeros(H);
      tmpca1 = adimat_pop;
      a_H = a_H + call(@triu, a_tmpca1);
      a_tmpca1 = a_zeros(tmpca1);
      tmpca2 = adimat_pop;
      a_tmpca3 = a_tmpca3 + call(@real, a_tmpca2);
      a_tmpca2 = a_zeros(tmpca2);
      tmpca3 = adimat_pop;
      a_tmpca4 = a_tmpca4 + call(@triu, a_tmpca3, -1);
      a_tmpca3 = a_zeros(tmpca3);
      tmpca4 = adimat_pop;
      a_H = a_H + call(@tril, a_tmpca4, -1);
      a_tmpca4 = a_zeros(tmpca4);
   end
   tmpfra1_2 = adimat_pop;
   for k=fliplr(1 : tmpfra1_2)
      H = adimat_pop;
      a_tmpca1 = a_tmpca1 + adimat_adjmultl(tmpca1, a_H, Pk);
      a_Pk = a_Pk + adimat_adjmultr(Pk, tmpca1, a_H);
      a_H = a_zeros(H);
      tmpca1 = adimat_pop;
      a_Pk = a_Pk + a_transpose(adimat_adjmultl(Pk', a_tmpca1, H), Pk);
      a_H = a_H + adimat_adjmultr(H, Pk', a_tmpca1);
      a_tmpca1 = a_zeros(tmpca1);
      Q = adimat_pop;
      a_Pk = a_Pk + adimat_adjmultr(Pk, Q, a_Q);
      tmpsa1 = a_Q;
      a_Q = a_zeros(Q);
      a_Q = a_Q + adimat_adjmultl(Q, tmpsa1, Pk);
      [tmpadjc1] = ret_mk_householder_elim(a_Pk);
      Pk = adimat_pop;
      a_H = a_H + tmpadjc1;
      a_Pk = a_zeros(Pk);
   end
   a_A = a_A + a_H;
end

function [Q H] = rec_adimat_hess(A)
   tmpca1 = 0;
   tmpca2 = 0;
   tmpca4 = 0;
   tmpca3 = 0;
   Pk = 0;
   n = size(A, 1);
   Q = eye(n);
   H = A;
   tmpfra1_2 = n - 1;
   for k=1 : tmpfra1_2
      adimat_push(Pk);
      Pk = rec_mk_householder_elim(H, k + 1, k);
      adimat_push(Q);
      Q = Q * Pk;
      adimat_push(tmpca1);
      tmpca1 = Pk' * H;
      adimat_push(H);
      H = tmpca1 * Pk;
   end
   adimat_push(tmpfra1_2);
   tmpba1 = 0;
   if adimat_issymmetric(H)
      tmpba1 = 1;
      adimat_push(tmpca2);
      tmpca2 = real(H);
      adimat_push(tmpca1);
      tmpca1 = triu(tmpca2, -1);
      adimat_push(H);
      H = tril(tmpca1, 1);
   else
      adimat_push(tmpca4);
      tmpca4 = tril(H, -1);
      adimat_push(tmpca3);
      tmpca3 = triu(tmpca4, -1);
      adimat_push(tmpca2);
      tmpca2 = real(tmpca3);
      adimat_push(tmpca1);
      tmpca1 = triu(H);
      adimat_push(H);
      H = tmpca1 + tmpca2;
   end
   adimat_push(tmpba1, Pk, n, tmpca1, tmpca2, tmpca4, tmpca3, Q, H, A);
end

function a_A = ret_adimat_hess(a_Q, a_H)
   [A H Q tmpca3 tmpca4 tmpca2 tmpca1 n Pk] = adimat_pop;
   [a_Pk a_tmpca1 a_tmpca2 a_tmpca4 a_tmpca3 a_A] = a_zeros(Pk, tmpca1, tmpca2, tmpca4, tmpca3, A);
   if nargin < 1
      a_Q = a_zeros(Q);
   end
   if nargin < 2
      a_H = a_zeros(H);
   end
   tmpba1 = adimat_pop;
   if tmpba1 == 1
      H = adimat_pop;
      a_tmpca1 = a_tmpca1 + call(@tril, a_H, 1);
      a_H = a_zeros(H);
      tmpca1 = adimat_pop;
      a_tmpca2 = a_tmpca2 + call(@triu, a_tmpca1, -1);
      a_tmpca1 = a_zeros(tmpca1);
      tmpca2 = adimat_pop;
      a_H = a_H + call(@real, a_tmpca2);
      a_tmpca2 = a_zeros(tmpca2);
   else
      H = adimat_pop;
      a_tmpca1 = a_tmpca1 + adimat_adjred(tmpca1, a_H);
      a_tmpca2 = a_tmpca2 + adimat_adjred(tmpca2, a_H);
      a_H = a_zeros(H);
      tmpca1 = adimat_pop;
      a_H = a_H + call(@triu, a_tmpca1);
      a_tmpca1 = a_zeros(tmpca1);
      tmpca2 = adimat_pop;
      a_tmpca3 = a_tmpca3 + call(@real, a_tmpca2);
      a_tmpca2 = a_zeros(tmpca2);
      tmpca3 = adimat_pop;
      a_tmpca4 = a_tmpca4 + call(@triu, a_tmpca3, -1);
      a_tmpca3 = a_zeros(tmpca3);
      tmpca4 = adimat_pop;
      a_H = a_H + call(@tril, a_tmpca4, -1);
      a_tmpca4 = a_zeros(tmpca4);
   end
   tmpfra1_2 = adimat_pop;
   for k=fliplr(1 : tmpfra1_2)
      H = adimat_pop;
      a_tmpca1 = a_tmpca1 + adimat_adjmultl(tmpca1, a_H, Pk);
      a_Pk = a_Pk + adimat_adjmultr(Pk, tmpca1, a_H);
      a_H = a_zeros(H);
      tmpca1 = adimat_pop;
      a_Pk = a_Pk + a_transpose(adimat_adjmultl(Pk', a_tmpca1, H), Pk);
      a_H = a_H + adimat_adjmultr(H, Pk', a_tmpca1);
      a_tmpca1 = a_zeros(tmpca1);
      Q = adimat_pop;
      a_Pk = a_Pk + adimat_adjmultr(Pk, Q, a_Q);
      tmpsa1 = a_Q;
      a_Q = a_zeros(Q);
      a_Q = a_Q + adimat_adjmultl(Q, tmpsa1, Pk);
      [tmpadjc1] = ret_mk_householder_elim(a_Pk);
      Pk = adimat_pop;
      a_H = a_H + tmpadjc1;
      a_Pk = a_zeros(Pk);
   end
   a_A = a_A + a_H;
end
% $Id: adimat_hess.m 3824 2013-07-16 11:49:54Z willkomm $

function [a_A nr_Pk] = a_mk_householder_elim(A, i, j, a_Pk)
   n = size(A, 1);
   uk = A(i : n, j);
   Pk = rec_mk_householder_elim_vec_lapack(uk, n);
   nr_Pk = Pk;
   [a_uk a_A] = a_zeros(uk, A);
   if nargin < 4
      a_Pk = a_zeros(Pk);
   end
   [tmpadjc1] = ret_mk_householder_elim_vec_lapack(a_Pk);
   a_uk = a_uk + tmpadjc1;
   a_A(i : n, j) = a_A(i : n, j) + a_uk;
end

function Pk = rec_mk_householder_elim(A, i, j)
   n = size(A, 1);
   uk = A(i : n, j);
   Pk = rec_mk_householder_elim_vec_lapack(uk, n);
   adimat_push(n, uk, Pk, A);
   if nargin > 1
      adimat_push(i);
   end
   if nargin > 2
      adimat_push(j);
   end
   adimat_push(nargin);
end

function a_A = ret_mk_householder_elim(a_Pk)
   tmpnargin = adimat_pop;
   if tmpnargin > 2
      j = adimat_pop;
   end
   if tmpnargin > 1
      i = adimat_pop;
   end
   [A Pk uk n] = adimat_pop;
   [a_uk a_A] = a_zeros(uk, A);
   if nargin < 1
      a_Pk = a_zeros(Pk);
   end
   [tmpadjc1] = ret_mk_householder_elim_vec_lapack(a_Pk);
   a_uk = a_uk + tmpadjc1;
   a_A(i : n, j) = a_A(i : n, j) + a_uk;
end
% $Id%

function [a_a nr_Pk nr_u] = a_mk_householder_elim_vec_lapack(a, n, a_Pk, a_u)
   tmplia1 = 0;
   tmpca1 = 0;
   tmpca3 = 0;
   tmpca2 = 0;
   tmpda1 = 0;
   tmpda2 = 0;
   u = 0;
   na = 0;
   sa1 = 0;
   nu = 0;
   sigma = 0;
   Pksub = 0;
   assert(iscolumn(a));
   Pk = eye(n);
   k = length(a);
   tmpba1 = 0;
   if ~(k==1 && isreal(a)) && sum(abs(a))~=0
      tmpba1 = 1;
      adimat_push(u);
      u = a;
      adimat_push(na);
      na = norm(a);
      tmpba2 = 0;
      if na ~= 0
         tmpba2 = 1;
         adimat_push(sa1);
         sa1 = sign(real(a(1)));
         tmpba3 = 0;
         if sa1 == 0
            tmpba3 = 1;
            a;
            adimat_push(sa1);
            sa1 = 1;
         end
         adimat_push(tmpba3, nu);
         nu = sa1 .* na;
         adimat_push(tmplia1);
         tmplia1 = u(1) + nu;
         adimat_push_index(u, 1);
         u(1) = tmplia1;
         adimat_push(tmpca1);
         tmpca1 = a(1) + nu;
         adimat_push(u);
         u = u ./ tmpca1;
         adimat_push(tmpca1);
         tmpca1 = a(1) + nu;
         adimat_push(sigma);
         sigma = tmpca1 ./ nu;
         adimat_push(tmpca3);
         tmpca3 = sigma .* u;
         adimat_push(tmpca2);
         tmpca2 = tmpca3 * u';
         adimat_push(tmpda1);
         tmpda1 = eye(k);
         adimat_push(Pksub);
         Pksub = tmpda1 - tmpca2;
         adimat_push(tmpda2);
         tmpda2 = n - k + 1;
         adimat_push(tmpda1);
         tmpda1 = n - k + 1;
         adimat_push_index(Pk, tmpda1 : adimat_end(Pk, 1, 2), tmpda2 : adimat_end(Pk, 2, 2));
         Pk(tmpda1 : end, tmpda2 : end) = Pksub;
      end
      adimat_push(tmpba2);
   end
   adimat_push(tmpba1);
   nr_Pk = Pk;
   nr_u = u;
   [a_na a_nu a_sigma a_Pksub a_tmplia1 a_tmpca1 a_tmpca3 a_tmpca2 a_a] = a_zeros(na, nu, sigma, Pksub, tmplia1, tmpca1, tmpca3, tmpca2, a);
   if nargin < 3
      a_Pk = a_zeros(Pk);
   end
   if nargin < 4
      a_u = a_zeros(u);
   end
   tmpba1 = adimat_pop;
   if tmpba1 == 1
      tmpba2 = adimat_pop;
      if tmpba2 == 1
         Pk = adimat_pop_index(Pk, tmpda1 : adimat_end(Pk, 1, 2), tmpda2 : adimat_end(Pk, 2, 2));
         a_Pksub = a_Pksub + adimat_adjred(Pksub, adimat_adjreshape(Pksub, a_Pk(tmpda1 : end, tmpda2 : end)));
         a_Pk = a_zeros_index(a_Pk, Pk, tmpda1 : adimat_end(Pk, 1, 2), tmpda2 : adimat_end(Pk, 2, 2));
         [tmpda1 tmpda2 Pksub] = adimat_pop;
         a_tmpca2 = a_tmpca2 + adimat_adjred(tmpca2, -a_Pksub);
         a_Pksub = a_zeros(Pksub);
         [tmpda1 tmpca2] = adimat_pop;
         a_tmpca3 = a_tmpca3 + adimat_adjmultl(tmpca3, a_tmpca2, u');
         a_u = a_u + a_transpose(adimat_adjmultr(u', tmpca3, a_tmpca2), u);
         a_tmpca2 = a_zeros(tmpca2);
         tmpca3 = adimat_pop;
         a_sigma = a_sigma + adimat_adjred(sigma, a_tmpca3 .* u);
         a_u = a_u + adimat_adjred(u, sigma .* a_tmpca3);
         a_tmpca3 = a_zeros(tmpca3);
         sigma = adimat_pop;
         a_tmpca1 = a_tmpca1 + adimat_adjred(tmpca1, a_sigma ./ nu);
         a_nu = a_nu + adimat_adjred(nu, -(((tmpca1 ./ nu) .* a_sigma) ./ nu));
         a_sigma = a_zeros(sigma);
         tmpca1 = adimat_pop;
         a_a(1) = a_a(1) + adimat_adjred(a(1), a_tmpca1);
         a_nu = a_nu + adimat_adjred(nu, a_tmpca1);
         a_tmpca1 = a_zeros(tmpca1);
         u = adimat_pop;
         a_tmpca1 = a_tmpca1 + adimat_adjred(tmpca1, -(((u ./ tmpca1) .* a_u) ./ tmpca1));
         tmpsa1 = a_u;
         a_u = a_zeros(u);
         a_u = a_u + adimat_adjred(u, tmpsa1 ./ tmpca1);
         tmpca1 = adimat_pop;
         a_a(1) = a_a(1) + adimat_adjred(a(1), a_tmpca1);
         a_nu = a_nu + adimat_adjred(nu, a_tmpca1);
         a_tmpca1 = a_zeros(tmpca1);
         u = adimat_pop_index(u, 1);
         a_tmplia1 = a_tmplia1 + adimat_adjred(tmplia1, adimat_adjreshape(tmplia1, a_u(1)));
         a_u = a_zeros_index(a_u, u, 1);
         tmplia1 = adimat_pop;
         a_u(1) = a_u(1) + adimat_adjred(u(1), a_tmplia1);
         a_nu = a_nu + adimat_adjred(nu, a_tmplia1);
         a_tmplia1 = a_zeros(tmplia1);
         nu = adimat_pop;
         a_na = a_na + adimat_adjred(na, sa1 .* a_nu);
         a_nu = a_zeros(nu);
         tmpba3 = adimat_pop;
         if tmpba3 == 1
            sa1 = adimat_pop;
            a;
            a_a;
         end
         sa1 = adimat_pop;
      end
      na = adimat_pop;
      a_a = a_a + a_adimat_norm1(a, a_na);
      a_na = a_zeros(na);
      u = adimat_pop;
      a_a = a_a + a_u;
      a_u = a_zeros(u);
   end
   assert(iscolumn(a));
end

function [Pk u] = rec_mk_householder_elim_vec_lapack(a, n)
   tmplia1 = 0;
   tmpca1 = 0;
   tmpca3 = 0;
   tmpca2 = 0;
   tmpda1 = 0;
   tmpda2 = 0;
   u = 0;
   na = 0;
   sa1 = 0;
   nu = 0;
   sigma = 0;
   Pksub = 0;
   assert(iscolumn(a));
   Pk = eye(n);
   k = length(a);
   tmpba1 = 0;
   if ~(k==1 && isreal(a)) && sum(abs(a))~=0
      tmpba1 = 1;
      adimat_push(u);
      u = a;
      adimat_push(na);
      na = norm(a);
      tmpba2 = 0;
      if na ~= 0
         tmpba2 = 1;
         adimat_push(sa1);
         sa1 = sign(real(a(1)));
         tmpba3 = 0;
         if sa1 == 0
            tmpba3 = 1;
            a;
            adimat_push(sa1);
            sa1 = 1;
         end
         adimat_push(tmpba3, nu);
         nu = sa1 .* na;
         adimat_push(tmplia1);
         tmplia1 = u(1) + nu;
         adimat_push_index(u, 1);
         u(1) = tmplia1;
         adimat_push(tmpca1);
         tmpca1 = a(1) + nu;
         adimat_push(u);
         u = u ./ tmpca1;
         adimat_push(tmpca1);
         tmpca1 = a(1) + nu;
         adimat_push(sigma);
         sigma = tmpca1 ./ nu;
         adimat_push(tmpca3);
         tmpca3 = sigma .* u;
         adimat_push(tmpca2);
         tmpca2 = tmpca3 * u';
         adimat_push(tmpda1);
         tmpda1 = eye(k);
         adimat_push(Pksub);
         Pksub = tmpda1 - tmpca2;
         adimat_push(tmpda2);
         tmpda2 = n - k + 1;
         adimat_push(tmpda1);
         tmpda1 = n - k + 1;
         adimat_push_index(Pk, tmpda1 : adimat_end(Pk, 1, 2), tmpda2 : adimat_end(Pk, 2, 2));
         Pk(tmpda1 : end, tmpda2 : end) = Pksub;
      end
      adimat_push(tmpba2);
   end
   adimat_push(tmpba1, na, sa1, nu, sigma, Pksub, k, tmplia1, tmpca1, tmpca3, tmpca2, tmpda1, tmpda2, Pk, u, a);
   if nargin > 1
      adimat_push(n);
   end
   adimat_push(nargin);
end

function a_a = ret_mk_householder_elim_vec_lapack(a_Pk, a_u)
   tmpnargin = adimat_pop;
   if tmpnargin > 1
      n = adimat_pop;
   end
   [a u Pk tmpda2 tmpda1 tmpca2 tmpca3 tmpca1 tmplia1 k Pksub sigma nu sa1 na] = adimat_pop;
   [a_na a_nu a_sigma a_Pksub a_tmplia1 a_tmpca1 a_tmpca3 a_tmpca2 a_a] = a_zeros(na, nu, sigma, Pksub, tmplia1, tmpca1, tmpca3, tmpca2, a);
   if nargin < 1
      a_Pk = a_zeros(Pk);
   end
   if nargin < 2
      a_u = a_zeros(u);
   end
   tmpba1 = adimat_pop;
   if tmpba1 == 1
      tmpba2 = adimat_pop;
      if tmpba2 == 1
         Pk = adimat_pop_index(Pk, tmpda1 : adimat_end(Pk, 1, 2), tmpda2 : adimat_end(Pk, 2, 2));
         a_Pksub = a_Pksub + adimat_adjred(Pksub, adimat_adjreshape(Pksub, a_Pk(tmpda1 : end, tmpda2 : end)));
         a_Pk = a_zeros_index(a_Pk, Pk, tmpda1 : adimat_end(Pk, 1, 2), tmpda2 : adimat_end(Pk, 2, 2));
         [tmpda1 tmpda2 Pksub] = adimat_pop;
         a_tmpca2 = a_tmpca2 + adimat_adjred(tmpca2, -a_Pksub);
         a_Pksub = a_zeros(Pksub);
         [tmpda1 tmpca2] = adimat_pop;
         a_tmpca3 = a_tmpca3 + adimat_adjmultl(tmpca3, a_tmpca2, u');
         a_u = a_u + a_transpose(adimat_adjmultr(u', tmpca3, a_tmpca2), u);
         a_tmpca2 = a_zeros(tmpca2);
         tmpca3 = adimat_pop;
         a_sigma = a_sigma + adimat_adjred(sigma, a_tmpca3 .* u);
         a_u = a_u + adimat_adjred(u, sigma .* a_tmpca3);
         a_tmpca3 = a_zeros(tmpca3);
         sigma = adimat_pop;
         a_tmpca1 = a_tmpca1 + adimat_adjred(tmpca1, a_sigma ./ nu);
         a_nu = a_nu + adimat_adjred(nu, -(((tmpca1 ./ nu) .* a_sigma) ./ nu));
         a_sigma = a_zeros(sigma);
         tmpca1 = adimat_pop;
         a_a(1) = a_a(1) + adimat_adjred(a(1), a_tmpca1);
         a_nu = a_nu + adimat_adjred(nu, a_tmpca1);
         a_tmpca1 = a_zeros(tmpca1);
         u = adimat_pop;
         a_tmpca1 = a_tmpca1 + adimat_adjred(tmpca1, -(((u ./ tmpca1) .* a_u) ./ tmpca1));
         tmpsa1 = a_u;
         a_u = a_zeros(u);
         a_u = a_u + adimat_adjred(u, tmpsa1 ./ tmpca1);
         tmpca1 = adimat_pop;
         a_a(1) = a_a(1) + adimat_adjred(a(1), a_tmpca1);
         a_nu = a_nu + adimat_adjred(nu, a_tmpca1);
         a_tmpca1 = a_zeros(tmpca1);
         u = adimat_pop_index(u, 1);
         a_tmplia1 = a_tmplia1 + adimat_adjred(tmplia1, adimat_adjreshape(tmplia1, a_u(1)));
         a_u = a_zeros_index(a_u, u, 1);
         tmplia1 = adimat_pop;
         a_u(1) = a_u(1) + adimat_adjred(u(1), a_tmplia1);
         a_nu = a_nu + adimat_adjred(nu, a_tmplia1);
         a_tmplia1 = a_zeros(tmplia1);
         nu = adimat_pop;
         a_na = a_na + adimat_adjred(na, sa1 .* a_nu);
         a_nu = a_zeros(nu);
         tmpba3 = adimat_pop;
         if tmpba3 == 1
            sa1 = adimat_pop;
            a;
            a_a;
         end
         sa1 = adimat_pop;
      end
      na = adimat_pop;
      a_a = a_a + a_adimat_norm1(a, a_na);
      a_na = a_zeros(na);
      u = adimat_pop;
      a_a = a_a + a_u;
      a_u = a_zeros(u);
   end
   assert(iscolumn(a));
end
% $Id%
