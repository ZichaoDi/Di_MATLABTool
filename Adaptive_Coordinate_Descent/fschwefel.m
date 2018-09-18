function y = schwefel(X)
%y = schwefel(X)
%Input
%- X: d-by-n matrix, d is the dimension and n is the number of inputs.
%Output
%- y: 1-by-n vector.
	[d, n] = size(X);
	y = zeros(1, n);
	
	for i = 1:n
		x = X(:,i);
		for j = 1:d
			y(i) = y(i) + sum(x(1:j))^2;
		end
	end
