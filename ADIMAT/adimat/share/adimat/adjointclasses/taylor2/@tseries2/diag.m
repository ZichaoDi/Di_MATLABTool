function obj = diag(obj)
  obj = unop(obj, @diag);
end
