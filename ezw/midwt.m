function [y,L] = midwt(x,h,L);
%    [x,L] = midwt(y,h,L);
% 
%    MIDWT computes the inverse discrete wavelet transform x for a 1D or 2D
%    input signal y using the scaling filter h.
%
%    Input:
%	y : finite length 1D or 2D input signal (implicitly periodized)
%       h : scaling filter
%       L : number of levels. In the case of a 1D signal, length(x) must be
%           divisible by 2^L; in hte case of a 2D signal, the row and the
%           column dimension must be divisible by 2^L.  If no argument is
%           specified, a full inverse DWT is returned for maximal possible
%           L.
%
%    Output:
%       x : periodic reconstructed signal
%       L : number of levels
%
%    Example:
%       xin = makesig('LinChirp',8);
%       h = daubcqf(4,'min');
%       L = 1;
%       [y,L] = mdwt(xin,h,L);
%       [x,L] = midwt(y,h,L)
%       x = 0.0491 0.1951 0.4276 0.7071 0.9415 0.9808 0.6716 0.0000
%       L = 1
%
%    See also: mdwt, mrdwt, mirdwt
%

%File Name: midwt.m
%Last Modification Date: 8/7/95	15:13:52
%Current Version: midwt.m	1.2
%File Creation Date: Wed Oct 19 10:51:58 1994
%Author: Markus Lang  <lang@jazz.rice.edu>
%
%Copyright: All software, documentation, and related files in this distribution
%           are Copyright (c) 1994 Rice University
%
%Permission is granted for use and non-profit distribution providing that this
%notice be clearly maintained. The right to distribute any portion for profit
%or as part of any commercial product is specifically reserved for the author.
%
%Change History:
% 
%Modification #1
%Mon Aug  7 11:52:33 CDT 1995
%Rebecca Hindman <hindman@ece.rice.edu>
%Added L to function line so that it can be displayed as an output
% 
