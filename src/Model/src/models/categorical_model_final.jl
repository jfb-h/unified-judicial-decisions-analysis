
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
    # board information
    boards::Vector{Int}
    N_boards::Int
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
    # boards
    boards = map(d -> id(board(d)), decisions)
    N_boards = maximum(boards)
    # years
    years = map(d -> Dates.year(date(d)) - 2000 + 1, decisions)
    N_years = maximum(years)

    BPatGModel(
        outcomes, outcome_labels, 
        js, n_js, N_js, 
        cpcs, n_cpcs, N_cpcs,
        boards, N_boards,
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
        cpcs, n_cpcs, N_cpcs,
        boards, N_boards,
        years, N_years,
    ) = problem

    (; α, zs, σs, zy, σy, zj, σj, zt, σt, ) = θ

    loglik = sum(zip(outcomes, boards, years, js, n_js, cpcs, n_cpcs)) do (oi, si, yi, ji, nji, ti, nti)
        jterm = nji > 0 ? sum(zj[j] .* σj for j in ji) ./ nji : zeros(2) # handle missing judges for year 2007

        η = α + zs[si] .* σs + zy[yi] .* σy + jterm +
            sum(zt[t] .* σt for t in ti) ./ nti
            
        p = softmax(vcat(0.0, η))
        logpdf(Categorical(p), oi)
    end

    logprior_hierarchical(zs, σs; centered=true) = begin
        Σ = centered ? diagm(σs) : I
        sum(logpdf(Exponential(1), σ) for σ in σs) +
        sum(logpdf(MvNormal(Zeros(2), Σ), z) for z in zs)
    end

    logpri = logpdf(MvNormal(Zeros(2), I), α) + 
             logprior_hierarchical(zs, σs; centered=false) + 
             logprior_hierarchical(zy, σy; centered=false) +
             logprior_hierarchical(zj, σj; centered=false) + 
             logprior_hierarchical(zt, σt; centered=false)

    loglik + logpri
end

function Model.transformation(problem::BPatGModel)
    as((
        α=as(Vector, asℝ, 2),
        zs=as(Vector, as(Vector, 2), problem.N_boards),
        σs=as(Vector, asℝ₊, 2),
        zy=as(Vector, as(Vector, 2), problem.N_years),
        σy=as(Vector, asℝ₊, 2),
        zj=as(Vector, as(Vector, 2), problem.N_js),   
        σj=as(Vector, asℝ₊, 2),
        zt=as(Vector, as(Vector, 2), problem.N_cpcs), 
        σt=as(Vector, asℝ₊, 2),
    ))
end

# function Model.predict(problem::BPatGModel, post::Model.AbstractPosterior; S=500)
#     map(first(post, S)) do s
#         map(problem.js) do j
#             softmax(vcat(0, sum(s.βs[j])))
#         end
#     end
# end