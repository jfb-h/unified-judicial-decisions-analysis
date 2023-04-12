
struct JudgesOnly <: Model.AbstractDecisionModel
  # Outcome information
  outcomes::Vector{Int}
  outcome_labels::Vector{String}
  # Judge information (multiple membership)
  js::Vector{Vector{Int}}
  n_js::Vector{Int}
  N_js::Int
end

function JudgesOnly(decisions::Vector{Decision})
  # outcomes
  outcome_labels = ["partially annulled", "annulled", "claim dismissed"]
  outcomes = [findfirst(==(label(outcome(d))), outcome_labels) for d in decisions]
  # judges
  js = map(d -> id.(Model.judges(d)), decisions)
  n_js = length.(js)
  N_js = maximum(reduce(vcat, js))

  JudgesOnly(
    outcomes, outcome_labels,
    js, n_js, N_js,
  )
end;

"""
    (problem::JudgesOnly)(θ)

Evaluate the log joint for an instance of `JudgesOnly` on parameters θ. 
Uses a non-centered parametrization.
"""
function (problem::JudgesOnly)(θ)
  (; outcomes, outcome_labels, js, n_js, N_js) = problem
  (; α, zj, σj) = θ

  loglik = sum(zip(outcomes, js, n_js)) do (oi, ji, nji)
    η = α + sum(zj[j] .* σj for j in ji) ./ nji

    p = softmax(vcat(0.0, η))
    logpdf(Categorical(p), oi)
  end

  logprior_hierarchical(zs, σs; centered=true) = begin
    Σ = centered ? diagm(σs) : I
    sum(logpdf(Exponential(1), σ) for σ in σs) +
    sum(logpdf(MvNormal(Zeros(2), Σ), z) for z in zs)
  end

  logpri = logpdf(MvNormal(Zeros(2), I), α) +
           logprior_hierarchical(zj, σj; centered=false)

  loglik + logpri
end

function Model.transformation(problem::JudgesOnly)
  as((
    α=as(Vector, asℝ, 2),
    zj=as(Vector, as(Vector, 2), problem.N_js),
    σj=as(Vector, asℝ₊, 2),
  ))
end

function loglikelihood(problem::JudgesOnly, θ::AbstractVector, datum)
  t = transformation(problem)
  (; outcome, js) = datum
  (; α, zj, σj) = TransformVariables.transform(t, θ)
  p = softmax(vcat(0, α .+ sum(zj[j] .* σj for j in js)))
  logpdf(Categorical(p), outcome)
end


