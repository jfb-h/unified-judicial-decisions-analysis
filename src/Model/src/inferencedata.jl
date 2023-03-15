
function param_indices(t)
    # TODO check nested transformations recursively
    i = 1
    map(t.transformations) do trans
        d = dimension(trans)
        start = i
        i += d
        start:(start - 1 + d)
    end
end

function InferenceObjects.convert_to_inference_data(problem::AbstractDecisionModel, post::DynamicHMCPosterior)
    stacks = DynamicHMC.stack_posterior_matrices(results(post))
    params = param_indices(transformation(problem))
    nt = map(params) do par
        stacks[:,:,par]
    end
    InferenceObjects.from_namedtuple(nt)
end

