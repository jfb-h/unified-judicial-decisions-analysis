using Model
using Dictionaries, SplitApplyCombine
using Distributions
using LogExpFunctions: softmax
using FillArrays
using LinearAlgebra
using TransformVariables
using StructArrays
using StaticArrays

using BenchmarkTools

struct MixedMembershipCategoricalModel <: Model.AbstractDecisionModel
    ys::Vector{Int}
    js::Vector{Vector{Int}}
    J::Int
    labels::Vector{String}
end

function MixedMembershipCategoricalModel(decisions::Vector{Decision})
    outcomes = ["annulled", "claim dismissed", "partially annulled"]
    ys = [findfirst(==(label(outcome(d))), outcomes) for d in decisions]    
    js = map(d -> id.(judges(d)), decisions) 
    J = length(unique(reduce(vcat, js)))
    MixedMembershipCategoricalModel(ys, js, J, outcomes)
end;

function loglikelihood(θ; problem)
    (; ys, js) = problem
    (; β) = θ

    sum(eachindex(ys)) do i
        jsᵢ = js[i]
        ηᵢ = sum(@views β[:,j] for j in jsᵢ)
        logpdf(Categorical(softmax(vcat(0.0, ηᵢ))), ys[i])
    end
end

function loglikelihood2(θ; problem)
    (; ys, js) = problem
    (; β) = θ

    sum(zip(ys, js)) do (y, ji)
        η = sum(β[j] for j in ji)
        logpdf(Categorical(softmax(vcat(0.0, η))), y)
    end
end

    

function logprior(θ)
    (; β) = θ
    k = size(β, 1)
    d = MvNormal(Zeros(k), I)
    sum(eachcol(β)) do p
        logpdf(d, p)
    end
end

function (problem::MixedMembershipCategoricalModel)(θ)
    loglikelihood(θ; problem) + logprior(θ)
end

function Model.transformation(problem::MixedMembershipCategoricalModel)
    as((β=as(Array, asℝ, (2, problem.J)),))
end