
struct MixedMembershipCategoricalModel <: Model.AbstractDecisionModel
    ys::Vector{Int}
    js::Vector{Vector{Int}}
    J::Int
    labels::Vector{String}
end

function MixedMembershipCategoricalModel(decisions::Vector{Decision})
    labels = ["annulled", "claim dismissed", "partially annulled"]
    ys = [findfirst(==(label(outcome(d))), labels) for d in decisions]    
    js = map(d -> id.(judges(d)), decisions) 
    J = length(unique(reduce(vcat, js)))
    MixedMembershipCategoricalModel(ys, js, J, labels)
end;

# function (problem::MixedMembershipCategoricalModel)(θ)
#     (; ys, js) = problem
#     (; βs, μs, σs) = θ

#     loglik = sum(zip(ys, js)) do (y, ji)
#         η = sum(βs[j] for j in ji)
#         logpdf(Categorical(softmax(vcat(0.0, η))), y)
#     end

#     logpri = sum(logpdf(Normal(0, 1), μ) for μ in μs) +
#              sum(logpdf(Exponential(1), σ) for σ in σs) +
#              sum(logpdf(MvNormal(μs, diagm(σs)), β) for β in βs)

#     loglik + logpri
# end

# function Model.transformation(problem::MixedMembershipCategoricalModel)
#     as((βs=as(Vector, as(Vector, 2), problem.J), μs=as(Vector, 2), σs=as(Vector, asℝ₊, 2)))
# end

function (problem::MixedMembershipCategoricalModel)(θ)
    # non-centered parametrization
    (; ys, js) = problem
    (; zs, μs, σs) = θ

    β(zs, μs, σs) = μs .+ zs.*σs

    loglik = sum(zip(ys, js)) do (y, ji)
        η = sum(β(zs[j], μs, σs) for j in ji) ./ 5
        logpdf(Categorical(softmax(vcat(0.0, η))), y)
    end

    logpri = sum(logpdf(Normal(0, 1), μ) for μ in μs) +
             sum(logpdf(Exponential(1), σ) for σ in σs) +
             sum(logpdf(MvNormal(Zeros(2), I), z) for z in zs)

    loglik + logpri
end

function Model.transformation(problem::MixedMembershipCategoricalModel)
    as((zs=as(Vector, as(Vector, 2), problem.J), μs=as(Vector, 2), σs=as(Vector, asℝ₊, 2)))
end

function Model.predict(problem::MixedMembershipCategoricalModel, post::Model.AbstractPosterior; S=500)
    map(first(post, S)) do s
        map(problem.js) do j
            softmax(vcat(0, sum(s.βs[j])))
        end
    end
end