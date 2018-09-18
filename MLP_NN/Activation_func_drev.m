%% Activation Function
function fx_drev = Activation_func_drev(fx, unipolarBipolarSelector)
    if (unipolarBipolarSelector == 0)
        fx_drev = fx .* (1 - fx); %Binary
    else
        fx_drev = 0.5 .* (1 + fx) .* (1 - fx); %Bipolar
    end
end