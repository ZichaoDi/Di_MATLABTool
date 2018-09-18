function bitStream = subordinatePass(slist,T,qno);
%
% bitStream = subordinatePass(slist,T,qno);
%
% Perform a subordinate pass
%
%    Input:
%	slist: subordinate list
%	T: threshold (overall)
%	qno: number of subordinate pass
%    Output:
%	bitStream: bit stream generated so far.
%
%   Reference: J. Shapiro, Embedded image coding using zerotree of wavelet 
%   coefficients, IEEE Trans. Signal Proc., vol. 41, no. 12, Dec. 1993.
%   Revised: Huipin Zhang, Mon Apr 12 19:30:44 CDT 1999

temp = floor(slist/T*2^qno);
bitStream = mod(temp,2);

return
