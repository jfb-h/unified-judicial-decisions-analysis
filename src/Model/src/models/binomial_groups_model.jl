"""
    BinomialGroupsModel

Simple hierarchical binomial model predicting the probability of annullment
by a grouping variable (e.g., board or year).
"""
struct BinomialGroupsModel{T} <: AbstractDecisionModel
    ys::Vector{Int}
    ns::Vector{Int}
    group::Vector{T}
end

function BinomialGroupsModel(decisions::Vector{Decision}; groupfun)
    gr = group(groupfun, id ∘ outcome, decisions)
    ys = map(sum, gr) |> sortkeys
    ns = map(length, gr) |> sortkeys
    BinomialGroupsModel(collect(ys), collect(ns), collect(keys(ns)))
end

function (problem::BinomialGroupsModel)(θ)
    (;αs, μ, σ) = θ
    (;ys, ns, group) = problem
    loglik = sum(logpdf(Binomial(n, logistic.(α)), y) for (n, α, y) in zip(ns, αs, ys))
    logpri = sum(logpdf(Normal(μ, σ), α) for α in αs) + logpdf(Normal(0, 1), μ) + logpdf(Exponential(1), σ)
    loglik + logpri
end

function transformation(problem::BinomialGroupsModel)
    as((αs=as(Array, asℝ, length(problem.group)), μ=asℝ, σ=asℝ₊))
end

function predict(problem::BinomialGroupsModel, post)
    map(s -> logistic.(s.αs), post)
end

function empirical(problem::BinomialGroupsModel)
    problem.ys ./ problem.ns
end