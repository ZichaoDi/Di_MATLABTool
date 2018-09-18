function [y,L] = mdwt(x,h,L);
%    [y,L] = mdwt(x,h,L);
%
%    MDWT computes the discrete wavelet transform y for a 1D or 2D input
%    signal x using the scaling filter h.
%
%    Input:
%	x : finite length 1D or 2D signal (implicitly periodized)
%       h : scaling filter
%       L : number of levels. In the case of a 1D signal, length(x) must be
%           divisible by 2^L; in the case of a 2D signal, the row and the
%           column dimension must be divisible by 2^L. If no argument is
%           specified, a full DWT is returned for maximal possible L.
%
%    Output:
%       y : the wavelet transform at all coarser levels
%       L : number of levels
%
%    Example:
%       x = makesig('LinChirp',8);
%       h = daubcqf(4,'min');
%       L = 1;
%       [y,L] = mdwt(x,h,L)
%       y = 0.1912 0.8821 1.4257 0.3101 -0.0339 0.1001 0.2201 -0.1401
%       L = 1
%
%    See also: midwt, mrdwt, mirdwt
%

%File Name: mdwt.m
%Last Modification Date: 8/7/95	15:13:25
%Current Version: mdwt.m	1.2
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
%Mon Aug  7 11:42:11 CDT 1995
%Rebecca Hindman <hindman@ece.rice.edu>
%Added L to function line so that it can be displayed as an output
%

