
struct BPatGModel <: Model.AbstractDecisionModel
    # Outcome information
    outcomes::Vector{Int}
    outcome_labels::Vector{String}
    # Judge information (multiple membership)
    js::Vector{Vector{Int}}
    n_js::Vector{Int}
    N_js::Int
    # Technology information (multiple membership)
    cpcs::Vector{Vector{Int}}
    n_cpcs::Vector{Int}
    N_cpcs::Int
    # Senate information
    senates::Vector{Int}
    N_senates::Int
    # Year information
    years::Vector{Int}
    N_years::Int
end

function BPatGModel(decisions::Vector{Decision}; levelfun=class)
    # outcomes
    outcome_labels = ["partially annulled", "annulled", "claim dismissed"]
    outcomes = [findfirst(==(label(outcome(d))), outcome_labels) for d in decisions]    
    # judges
    js = map(d -> id.(Model.judges(d)), decisions)
    n_js = length.(js)
    N_js = maximum(reduce(vcat, js))
    # technologies
    cpcs, _ = cpc2int(decisions, levelfun)
    n_cpcs = length.(cpcs)
    N_cpcs = maximum(reduce(vcat, cpcs))
    # senates
    senates = map(id ∘ senate, decisions)
    N_senates = maximum(seneates)
    # years
    years = map(d -> Dates.year(date(d)) - 2000 + 1, decisions)
    N_years = maximum(years)
    
    BPatGModel(
        outcomes, outcome_labels, 
        js, n_js, N_js, 
        cpcs, n_cpcs, N_cpcs,
        senates, N_senates,
        years, N_years,
    )
end;

"""
    (problem::BPatGModel)(θ)

Evaluate the log joint for an instance of `BPatGModel` on parameters θ. 
Uses a non-centered parametrization.
"""
function (problem::BPatGModel)(θ)
    (; 
        outcomes, outcome_labels, 
        js, n_js, N_js, 
        cpcs, n_cpcs, N_cpcs
    ) = problem

    (; zj, σj, zt, σt, αs,) = θ

    logprior(zs, σs) = begin
        sum(logpdf(Exponential(1), σ) for σ in σs) +
        sum(logpdf(MvNormal(Zeros(2), I), z) for z in zs)
    end

    loglik = sum(zip(outcomes, js, n_js, cpcs, n_cpcs)) do (yi, ji, nji, ti, nti)
        η = sum(zj[j] .* σj for j in ji) ./ nji +
            sum(zt[t] .* σt for t in ti) ./ nti + αs
        p = softmax(vcat(0.0, η))
        logpdf(Categorical(p), yi)
    end

    logpri = logpdf(MvNormal(Zeros(2), I), αs) + 
             logprior(zj, σj) + 
             logprior(zt, σt)

    loglik + logpri
end

function Model.transformation(problem::BPatGModel)
    as((
        zj=as(Vector, as(Vector, 2), problem.N_js),   
        zt=as(Vector, as(Vector, 2), problem.N_cpcs), 
        σj=as(Vector, asℝ₊, 2),
        σt=as(Vector, asℝ₊, 2),
        αs=as(Vector, asℝ, 2),
    ))
end

# function Model.predict(problem::BPatGModel, post::Model.AbstractPosterior; S=500)
#     map(first(post, S)) do s
#         map(problem.js) do j
#             softmax(vcat(0, sum(s.βs[j])))
#         end
#     end
# end