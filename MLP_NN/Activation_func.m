%% Activation Function
function fx = Activation_func(x, unipolarBipolarSelector)
    if (unipolarBipolarSelector == 0)
        fx = 1./(1 + exp(-x)); %Binary
    else
        fx = -1 + 2./(1 + exp(-x)); %Bipolar
    end
end