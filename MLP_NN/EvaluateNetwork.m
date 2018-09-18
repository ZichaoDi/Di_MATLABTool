function outputs = EvaluateNetwork(Sample, NodesActivations, Weights, unipolarBipolarSelector)

nbrOfLayers = length(NodesActivations);

NodesActivations{1} = Sample;
for Layer = 2:nbrOfLayers
    NodesActivations{Layer} = NodesActivations{Layer-1}*Weights{Layer-1};
    NodesActivations{Layer} = Activation_func(NodesActivations{Layer}, unipolarBipolarSelector);
    if (Layer ~= nbrOfLayers) %Because bias nodes don't have weights connected to previous layer
        NodesActivations{Layer}(1) = 1;
    end
end

outputs = NodesActivations{end};

end