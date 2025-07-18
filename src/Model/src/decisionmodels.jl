abstract type AbstractDecisionModel end
abstract type AbstractInferenceAlgorithm end
abstract type AbstractPosterior end

"""
    transformation(problem)

Transform parameters to the unconstraint Real numbers. 
Implement this using `TransformVariables.as` on a per-model basis.
"""
function transformation(problem)
  throw(ArgumentError("Not implemented for $(typeof(problem))"))
end

"""
    DynamicHMCPosterior

struct representing the posterior distribution of a model's parameters sampled with DynamicHMC.
Also used for dispatch in the `sample` method.
"""
struct DynamicHMCPosterior{T,S,R} <: AbstractPosterior
  post::T
  stat::S
  res::R
end

stats(x::DynamicHMCPosterior) = getfield(x, :stat)
_post(x::DynamicHMCPosterior) = getfield(x, :post)
results(x::DynamicHMCPosterior) = getfield(x, :res)

paramnames(x::DynamicHMCPosterior) = keys(first(_post(x)))

Base.length(x::DynamicHMCPosterior) = length(_post(x))
Base.getindex(x::DynamicHMCPosterior, key) = getindex(_post(x), key)
Base.getproperty(x::DynamicHMCPosterior, f::Symbol) = getproperty(_post(x), f)

Base.iterate(x::DynamicHMCPosterior) = iterate(_post(x))
Base.iterate(x::DynamicHMCPosterior, state) = iterate(_post(x), state)

function Base.show(io::IO, ::MIME"text/plain", p::DynamicHMCPosterior)
  #compact = get(io, :compact, false)
  params = paramnames(p)
  print(io, "DynamicHMCPosterior with $(length(p)) samples and parameters $params")
end

struct NUTS <: AbstractInferenceAlgorithm end

"""
    sample(AbstractInferenceAlgorithm(), problem, iter)

Sample from the posterior distribution of `problem` with the sampling 
algorithm specified by the first argument, taking `iter` samples.
If the first argument is omitted, NUTS via `DynamicHMC`` is used by default.
"""
function sample(::NUTS, problem::AbstractDecisionModel, iter::Integer, chains::Integer=4; reporter=NoProgressReport())
  t = transformation(problem)
  ℓ = TransformedLogDensity(t, problem)

  res = ThreadsX.map(1:chains) do _
    ∇ℓ = ADgradient(:ReverseDiff, ℓ; compile=Val(true))
    mcmc_with_warmup(Random.default_rng(), ∇ℓ, iter; reporter)
  end
  post = StructArray(TransformVariables.transform.(t, eachcol(pool_posterior_matrices(res))))
  stat = [(tree_statistics=r.tree_statistics, κ=r.κ, ϵ=r.ϵ) for r in res]
  DynamicHMCPosterior(post, stat, res)
end
sample(problem, iter, chains; kwargs...) = sample(NUTS(), problem, iter, chains; kwargs...)


"""
    predict(problem, post)

Perform posterior prediction based on posterior distribution `post` over the data in `problem`.
"""
function predict(problem::AbstractDecisionModel, post::AbstractPosterior)
  throw(ArgumentError("Not implemented yet for $(typeof(problem)). Needs to be implemented on a per-model basis."))
end

"""
    checkconvergence(post)

Check effective sample sizes and convergence statistics for the NUTS algorithm.
"""
function checkconvergence(post::DynamicHMCPosterior)
  res = getfield(post, :res)
  ess, R̂ = ess_rhat(stack_posterior_matrices(res))
  treestats = summarize_tree_statistics(mapreduce(x -> x.tree_statistics, vcat, res))
  (; ess, R̂, treestats)
end
