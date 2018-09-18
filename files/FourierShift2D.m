function y = FourierShift2D(x, delta)
% The size of the matrix.
[N, M] = size(x);
xtemp=zeros(N+20,M+20);
xtemp(11:N+10,11:M+10)=x;
realInd_x=11:N+10;
realInd_y=11:M+10;
padInd_x=setdiff([1:N+20],realInd_x);
padInd_y=setdiff([1:M+20],realInd_y);

[N, M] = size(xtemp);
% FFT of our possibly padded input signal.
X = fft2(xtemp);

% The mathsy bit. The floors take care of odd-length signals.
x_shift = exp(-i * 2 * pi * delta(1) * [0:floor(N/2)-1 floor(-N/2):-1]' / N);
y_shift = exp(-i * 2 * pi * delta(2) * [0:floor(M/2)-1 floor(-M/2):-1] / M);


% Force conjugate symmetry. Otherwise this frequency component has no
% corresponding negative frequency to cancel out its imaginary part.
if mod(N, 2) == 0
    x_shift(N/2+1) = real(x_shift(N/2+1));
end 
if mod(M, 2) == 0
    y_shift(M/2+1) = real(y_shift(M/2+1));
end
Y = X .* (x_shift * y_shift);

% Invert the FFT.
y = ifft2(Y);
% There should be no imaginary component (for real input
% signals) but due to numerical effects some remnants remain.
if isreal(x)
    y = real(y);
end
y=y(realInd_x,realInd_y);
    
end
