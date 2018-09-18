function f=ftablet(x)
  f = 1e6*x(1,:).^2 + sum(x(2:end,:).^2, 1);
