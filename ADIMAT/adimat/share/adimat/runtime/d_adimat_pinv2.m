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
% Flags: FORWARDMODE,  NOOPEROPTIM,
%   NOLOCALCSE,  NOGLOBALCSE,  NOPRESCALARFOLDING,
%   NOPOSTSCALARFOLDING,  NOCONSTFOLDMULT0,  FUNCMODE,
%   NOTMPCLEAR,  DUMP_XML,  PARSE_ONLY,
%   UNBOUND_ERROR
%
% Parameters:
%  - dependents=z
%  - independents=A
%  - inputEncoding=ISO-8859-1
%  - output-mode: plain
%  - output-file: ad_out/d_adimat_pinv2.m
%  - output-file-prefix: 
%  - output-directory: ad_out
%
% Functions in this file: d_adimat_pinv2, d_adimat_svd,
%  d_adimat_safediag, d_adimat_onesided_jacobi, d_adimat_arnoldi,
%  d_mk_givens
%

function [d_z z] = d_adimat_pinv2(d_A, A, tol)
   U = [];
   d_U = d_zeros(U);
   S = [];
   d_S = d_zeros(S);
   V = [];
   d_V = d_zeros(V);
   if isreal(A)
      [d_U U d_S S d_V V] = adimat_diff_svd2(d_A, A);
   else
      [d_U U d_S S d_V V] = d_adimat_svd(d_A, A);
   end
   [d_d d] = d_adimat_safediag(d_S, S);
   nign = d > tol;
   d_d = adimat_opdiff_subsasgn(d_d, struct('type', {'()'}, 'subs', {{nign}}), adimat_opdiff_ediv_left(1, adimat_opdiff_subsref(d_d, struct('type', '()', 'subs', {{nign}})), d(nign)));
   d(nign) = 1 ./ d(nign);
   tmpva1 = 0;
   d(~nign) = tmpva1;
   d_d = adimat_opdiff_subsasgn(d_d, struct('type', {'()'}, 'subs', {{~nign}}), d_zeros(tmpva1));
   d_T = d_S;
   T = S;
   for i=1 : length(d)
      d_T = adimat_opdiff_subsasgn(d_T, struct('type', {'()'}, 'subs', {{i i}}), adimat_opdiff_subsref(d_d, struct('type', '()', 'subs', {{i}})));
      T(i, i) = d(i);
   end
   d_tmpca1 = adimat_opdiff_mult(d_V, V, adimat_opdiff_etrans(d_T, T), T.');
   tmpca1 = V * T.';
   d_z = adimat_opdiff_mult(d_tmpca1, tmpca1, adimat_opdiff_trans(d_U, U), U');
   z = tmpca1 * U';
end

function [d_U U d_S S d_V V] = d_adimat_svd(d_A, A)
   nargoutwrapper = [1 1 2 2 3 3];
   U = [];
   d_U = d_zeros(U);
   S = [];
   d_S = d_zeros(S);
   V = [];
   d_V = d_zeros(V);
   tmp = [];
   d_tmp = d_zeros(tmp);
   nA1 = [];
   svals = [];
   d_svals = d_zeros(svals);
   B = [];
   d_B = d_zeros(B);
   nt = [];
   neqz = [];
   tmpda3 = [];
   tmpda2 = [];
   tmpca1 = [];
   d_tmpca1 = d_zeros(tmpca1);
   qualArnoldi = [];
   count = [];
   maxArnoldiTries = [];
   rs = [];
   tmpda1 = [];
   Uprelim = [];
   d_Uprelim = d_zeros(Uprelim);
   Q = [];
   d_Q = d_zeros(Q);
   H = [];
   qsvd = [];
   [m n] = size(A);
   if m < n
      if nargoutwrapper(nargout) <= 1
         [d_U U] = d_adimat_svd(adimat_opdiff_trans(d_A, A), A');
      else
         [d_tmp tmp d_S S d_V V] = d_adimat_svd(adimat_opdiff_trans(d_A, A), A');
         d_U = d_V;
         U = V;
         d_V = d_tmp;
         V = tmp;
         d_S = adimat_opdiff_etrans(d_S, S);
         S = S.';
      end
   else
      nA1 = norm(A, 'fro');
      if nargoutwrapper(nargout) > 1
         [d_svals svals d_B B d_V V nt] = d_adimat_onesided_jacobi(d_A, A, nA1);
      else
         [d_svals svals] = d_adimat_onesided_jacobi(d_A, A, nA1);
      end
      neqz = svals ~= 0;
      [tmpada1 svals(neqz)] = adimat_diff_sqrt(adimat_opdiff_subsref(d_svals, struct('type', '()', 'subs', {{neqz}})), svals(neqz));
      d_svals = adimat_opdiff_subsasgn(d_svals, struct('type', {'()'}, 'subs', {{neqz}}), tmpada1);
      if nargoutwrapper(nargout) <= 1
         d_U = d_svals;
         U = svals;
      else
         d_U = d_B;
         U = B;
         for i=1 : nt
            if svals(i)./(svals(1) + eps) > eps
               d_U = adimat_opdiff_subsasgn(d_U, struct('type', {'()'}, 'subs', {{':' i}}), adimat_opdiff_ediv(adimat_opdiff_subsref(d_U, struct('type', '()', 'subs', {{':' i}})), U(:, i), adimat_opdiff_subsref(d_svals, struct('type', '()', 'subs', {{i}})), svals(i)));
               U(:, i) = U(:, i) ./ svals(i);
            else
               nt = min(i - 1, nt);
            end
         end
         tmpda3 = m - n;
         tmpda2 = zeros(tmpda3, n);
         [d_tmpca1 tmpca1] = adimat_diff_diag(d_svals, svals);
         d_S = adimat_fdiff_cat(2, adimat_fdiff_cat(3, d_tmpca1), adimat_fdiff_cat(3, d_zeros(tmpda2)));
         S = [tmpca1
               tmpda2];
         if nt == 0
            U = eye(m);
            d_U = d_zeros(U);
         elseif m > nt
            qualArnoldi = 1;
            count = 1;
            maxArnoldiTries = 20;
            rs = rand('state');
            rand('state', 1992);
            while qualArnoldi./nA1>eps.*10 && count<maxArnoldiTries
               if count == 1
                  tmpda2 = m - nt;
                  tmpda1 = eye(m, tmpda2);
                  d_Uprelim = adimat_fdiff_cat(3, adimat_opdiff_subsref(d_U, struct('type', '()', 'subs', {{':' 1 : nt}})), d_zeros(tmpda1));
                  Uprelim = [U(:, 1 : nt) tmpda1];
               else
                  tmpda2 = m - nt;
                  tmpda1 = rand(m, tmpda2);
                  d_Uprelim = adimat_fdiff_cat(3, adimat_opdiff_subsref(d_U, struct('type', '()', 'subs', {{':' 1 : nt}})), d_zeros(tmpda1));
                  Uprelim = [U(:, 1 : nt) tmpda1];
               end
               [d_Q Q H dummy qualArnoldi] = d_adimat_arnoldi(d_Uprelim, Uprelim, m, adimat_opdiff_subsref(d_U, struct('type', '()', 'subs', {{':' 1 : nt}})), U(:, 1 : nt));
               count = count + 1;
            end
            d_U = d_Q;
            U = Q;
            rand('state', rs);
            if count >= maxArnoldiTries
               error('adimat:svd_jacobi:too_many_base_tries', 'Too many tries (%d) to complete the left unitary base', count);
            end
         end
         qsvd = norm(S - U'*A*V, 1) ./ (norm(A, 1) + eps);
         assert(qsvd < eps(class(A)).*1000);
      end
   end
end

function [d_v v] = d_adimat_safediag(d_M, M)
   v = [];
   d_v = d_zeros(v);
   if isvector(M)
      d_v = adimat_opdiff_subsref(d_M, struct('type', '()', 'subs', {{1}}));
      v = M(1);
   else
      [d_v v] = adimat_diff_diag(d_M, M);
   end
end
% $Id: adimat_safediag.m 3917 2013-10-09 15:48:17Z willkomm $

function [d_z z d_A A d_V V nt] = d_adimat_onesided_jacobi(d_A, A, nA1)
   nargoutwrapper = [1 1 2 2 3 3 4];
   V = [];
   d_V = d_zeros(V);
   p = [];
   d_p = d_zeros(p);
   q = [];
   d_q = d_zeros(q);
   r = [];
   d_r = d_zeros(r);
   tmpca1 = [];
   d_tmpca1 = d_zeros(tmpca1);
   tmpca5 = [];
   d_tmpca5 = d_zeros(tmpca5);
   tmpca4 = [];
   d_tmpca4 = d_zeros(tmpca4);
   tmpca3 = [];
   d_tmpca3 = d_zeros(tmpca3);
   tmpca2 = [];
   d_tmpca2 = d_zeros(tmpca2);
   vt = [];
   d_vt = d_zeros(vt);
   s = [];
   d_s = d_zeros(s);
   c = [];
   d_c = d_zeros(c);
   G = [];
   d_G = d_zeros(G);
   [m n] = size(A);
   nt = n;
   slimit = max(n ./ 4, 6) .* 10;
   if nargoutwrapper(nargout) > 2
      V = eye(n, n);
      d_V = d_zeros(V);
   end
   z = zeros(nt, 1);
   d_z = d_zeros(z);
   if nt == 1
      d_z = adimat_opdiff_subsasgn(d_z, struct('type', {'()'}, 'subs', {{1}}), adimat_opdiff_mult(adimat_opdiff_trans(d_A, A), A', d_A, A));
      z(1) = A' * A;
   end
   tol = eps;
   noRotationHere = 0;
   scount = 0;
   rcount = (nt .* (nt - 1)) ./ 2;
   while scount<=slimit && rcount>0
      rcount = (nt .* (nt - 1)) ./ 2;
      for j=1 : nt-1
         for k=j+1 : nt
            noRotationHere = 0;
            d_p = adimat_opdiff_mult(adimat_opdiff_trans(adimat_opdiff_subsref(d_A, struct('type', '()', 'subs', {{':' j}})), A(:, j)), A(:, j)', adimat_opdiff_subsref(d_A, struct('type', '()', 'subs', {{':' k}})), A(:, k));
            p = A(:, j)' * A(:, k);
            d_q = adimat_opdiff_mult(adimat_opdiff_trans(adimat_opdiff_subsref(d_A, struct('type', '()', 'subs', {{':' j}})), A(:, j)), A(:, j)', adimat_opdiff_subsref(d_A, struct('type', '()', 'subs', {{':' j}})), A(:, j));
            q = A(:, j)' * A(:, j);
            d_r = adimat_opdiff_mult(adimat_opdiff_trans(adimat_opdiff_subsref(d_A, struct('type', '()', 'subs', {{':' k}})), A(:, k)), A(:, k)', adimat_opdiff_subsref(d_A, struct('type', '()', 'subs', {{':' k}})), A(:, k));
            r = A(:, k)' * A(:, k);
            d_z = adimat_opdiff_subsasgn(d_z, struct('type', {'()'}, 'subs', {{j}}), d_q);
            z(j) = q;
            d_z = adimat_opdiff_subsasgn(d_z, struct('type', {'()'}, 'subs', {{k}}), d_r);
            z(k) = r;
            if q < r
               d_tmpca1 = adimat_opdiff_ediv(d_q, q, d_r, r);
               tmpca1 = q ./ r;
               d_q = adimat_opdiff_sum(d_tmpca1, d_zeros(-1));
               q = tmpca1 - 1;
               d_p = adimat_opdiff_ediv(d_p, p, d_r, r);
               p = p ./ r;
               d_tmpca5 = adimat_opdiff_emult(d_q, q, d_q, q);
               tmpca5 = q .* q;
               d_tmpca4 = adimat_diff_conj(d_p, p);
               tmpca4 = conj(p);
               d_tmpca3 = adimat_opdiff_emult_left(4, d_tmpca4, tmpca4);
               tmpca3 = 4 .* tmpca4;
               d_tmpca2 = adimat_opdiff_emult(d_tmpca3, tmpca3, d_p, p);
               tmpca2 = tmpca3 .* p;
               d_tmpca1 = adimat_opdiff_sum(d_tmpca2, d_tmpca5);
               tmpca1 = tmpca2 + tmpca5;
               [d_vt vt] = adimat_diff_sqrt(d_tmpca1, tmpca1);
               d_tmpca3 = adimat_opdiff_ediv(d_q, q, d_vt, vt);
               tmpca3 = q ./ vt;
               d_tmpca2 = adimat_opdiff_sum(-d_tmpca3, d_zeros(1));
               tmpca2 = 1 - tmpca3;
               d_tmpca1 = adimat_opdiff_emult_left(0.5, d_tmpca2, tmpca2);
               tmpca1 = 0.5 .* tmpca2;
               [d_s s] = adimat_diff_sqrt(d_tmpca1, tmpca1);
               if p < 0
                  d_s = -d_s;
                  s = -s;
               end
               d_tmpca1 = adimat_opdiff_emult(d_vt, vt, d_s, s);
               tmpca1 = vt .* s;
               d_c = adimat_opdiff_ediv(d_p, p, d_tmpca1, tmpca1);
               c = p ./ tmpca1;
            elseif q.*r <= eps.^2.*nA1
               noRotationHere = 1;
            elseif (p ./ q)'.*p./r <= eps.^2.*nA1
               noRotationHere = 1;
            else
               d_tmpca1 = adimat_opdiff_ediv(d_r, r, d_q, q);
               tmpca1 = r ./ q;
               d_r = adimat_opdiff_sum(-d_tmpca1, d_zeros(1));
               r = 1 - tmpca1;
               d_p = adimat_opdiff_ediv(d_p, p, d_q, q);
               p = p ./ q;
               d_tmpca5 = adimat_opdiff_emult(d_r, r, d_r, r);
               tmpca5 = r .* r;
               d_tmpca4 = adimat_diff_conj(d_p, p);
               tmpca4 = conj(p);
               d_tmpca3 = adimat_opdiff_emult_left(4, d_tmpca4, tmpca4);
               tmpca3 = 4 .* tmpca4;
               d_tmpca2 = adimat_opdiff_emult(d_tmpca3, tmpca3, d_p, p);
               tmpca2 = tmpca3 .* p;
               d_tmpca1 = adimat_opdiff_sum(d_tmpca2, d_tmpca5);
               tmpca1 = tmpca2 + tmpca5;
               [d_vt vt] = adimat_diff_sqrt(d_tmpca1, tmpca1);
               d_tmpca3 = adimat_opdiff_ediv(d_r, r, d_vt, vt);
               tmpca3 = r ./ vt;
               d_tmpca2 = adimat_opdiff_sum(d_tmpca3, d_zeros(1));
               tmpca2 = 1 + tmpca3;
               d_tmpca1 = adimat_opdiff_emult_left(0.5, d_tmpca2, tmpca2);
               tmpca1 = 0.5 .* tmpca2;
               [d_c c] = adimat_diff_sqrt(d_tmpca1, tmpca1);
               d_tmpca1 = adimat_opdiff_emult(d_vt, vt, d_c, c);
               tmpca1 = vt .* c;
               d_s = adimat_opdiff_ediv(d_p, p, d_tmpca1, tmpca1);
               s = p ./ tmpca1;
            end
            if noRotationHere == 0
               [d_G G] = d_mk_givens(d_c, c, d_s, s, n, j, k);
               d_A = adimat_opdiff_mult(d_A, A, d_G, G);
               A = A * G;
               if nargoutwrapper(nargout) > 2
                  d_tmpca1 = adimat_opdiff_mult(d_V, V, d_G, G);
                  tmpca1 = V * G;
                  d_V = adimat_diff_full(d_tmpca1, tmpca1);
                  V = full(tmpca1);
               end
            else
               rcount = rcount - 1;
            end
         end
      end
      if nt > 1
         if z(nt)./(z(1) + tol) <= tol
            nt = nt - 1;
         end
      end
      scount = scount + 1;
   end
   if nargoutwrapper(nargout) > 1
   end
   if scount > slimit
      error('adimat:onesided_jacobi:too_many_sweeps', 'Too many sweeps (%d) in one-sided Jacobi scheme', scount);
   end
end
% $Id: adimat_onesided_jacobi.m 4162 2014-05-12 07:34:49Z willkomm $

function [d_Q Q H d_hkkm1 hkkm1] = d_adimat_arnoldi(d_A, A, m, d_qk, qk)
   narginwrapper = [0 1 2 0 3];
   hkkm1 = [];
   d_hkkm1 = d_zeros(hkkm1);
   tmpda2 = [];
   tmpda1 = [];
   hjkm1 = [];
   d_hjkm1 = d_zeros(hjkm1);
   n = size(A, 1);
   if narginwrapper(nargin) < 2
      m = n;
   end
   H = zeros(m);
   Q = eye(n, m);
   d_Q = d_zeros(Q);
   if narginwrapper(nargin) < 3
      if isreal(A)
         qk = rand(n, 1);
         d_qk = d_zeros(qk);
      else
         tmpda2 = rand(n, 1);
         tmpda1 = rand(n, 1);
         qk = complex(tmpda1, tmpda2);
         d_qk = d_zeros(qk);
      end
   end
   nexist = size(qk, 2);
   d_Q = adimat_opdiff_subsasgn(d_Q, struct('type', {'()'}, 'subs', {{':' 1 : nexist}}), d_qk);
   Q(:, 1 : nexist) = qk;
   d_qk = adimat_opdiff_subsref(d_qk, struct('type', '()', 'subs', {{':' adimat_end(qk, 2, 2)}}));
   qk = qk(:, end);
   d_tmpca1 = adimat_diff_norm1(d_qk, qk);
   tmpca1 = norm(qk);
   d_qk = adimat_opdiff_ediv(d_qk, qk, d_tmpca1, tmpca1);
   qk = qk ./ tmpca1;
   startInd = 1;
   for k=nexist+1 : m+1
      d_qk = adimat_opdiff_mult(d_A, A, d_qk, qk);
      qk = A * qk;
      for j=startInd : k-1
         d_hjkm1 = adimat_opdiff_mult(adimat_opdiff_trans(adimat_opdiff_subsref(d_Q, struct('type', '()', 'subs', {{':' j}})), Q(:, j)), Q(:, j)', d_qk, qk);
         hjkm1 = Q(:, j)' * qk;
         d_tmpca1 = adimat_opdiff_emult(d_hjkm1, hjkm1, adimat_opdiff_subsref(d_Q, struct('type', '()', 'subs', {{':' j}})), Q(:, j));
         tmpca1 = hjkm1 .* Q(:, j);
         d_qk = adimat_opdiff_sum(d_qk, -d_tmpca1);
         qk = qk - tmpca1;
         H(j, k - 1) = hjkm1;
      end
      if isequal(qk, 0)
         hkkm1 = 0;
         d_hkkm1 = d_zeros(hkkm1);
      else
         d_hkkm1 = adimat_diff_norm1(d_qk, qk);
         hkkm1 = norm(qk);
      end
      if k == m+1
         if m == n
            if hkkm1 > eps.*1e2
               warning('adimat:arnoldi:inaccurate', 'Large error in Arnoldi iteration k=%d:%g', k, hkkm1);
            end
            if hkkm1 > eps.*1e4
               warning('adimat:arnoldi:failure', 'Very large error in Arnoldi iteration k=%d:%g', k, hkkm1);
            end
         end
      else
         if hkkm1 < eps
            warning('adimat:arnoldi:breakdown', 'Breakdown in Arnoldi iteration at k=%d', k);
            break;
         end
      end
      if hkkm1==0 || k==m+1
         break;
      end
      d_qk = adimat_opdiff_ediv(d_qk, qk, d_hkkm1, hkkm1);
      qk = qk ./ hkkm1;
      H(k, k - 1) = hkkm1;
      d_Q = adimat_opdiff_subsasgn(d_Q, struct('type', {'()'}, 'subs', {{':' k}}), d_qk);
      Q(:, k) = qk;
   end
end
% $Id: adimat_arnoldi.m 3980 2013-12-21 11:03:40Z willkomm $

function [d_G G] = d_mk_givens(d_c, c, d_s, s, n, i, j)
   G = speye(n);
   d_G = d_zeros(G);
   d_G = adimat_opdiff_subsasgn(d_G, struct('type', {'()'}, 'subs', {{i i}}), d_c);
   G(i, i) = c;
   d_G = adimat_opdiff_subsasgn(d_G, struct('type', {'()'}, 'subs', {{j j}}), adimat_diff_conj(d_c, c));
   G(j, j) = conj(c);
   d_G = adimat_opdiff_subsasgn(d_G, struct('type', {'()'}, 'subs', {{i j}}), -d_s);
   G(i, j) = -s;
   d_G = adimat_opdiff_subsasgn(d_G, struct('type', {'()'}, 'subs', {{j i}}), adimat_diff_conj(d_s, s));
   G(j, i) = conj(s);
end
% $Id: mk_givens.m 4162 2014-05-12 07:34:49Z willkomm $
