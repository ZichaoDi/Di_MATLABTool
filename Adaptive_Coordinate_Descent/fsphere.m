function y = fsphere(X)
%y = sphere(X)
%Input
%- X: d-by-n matrix, d is the dimension and n is the number of inputs.
%Output
%- y: 1-by-n vector.
%y = rand();  return 

    y = sum( X.^2 );
