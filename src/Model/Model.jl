module Model

using Reexport: @reexport
@reexport using Statistics

using JSON3
using CSV
using Dates
using Dictionaries: Dictionary, dictionary, sortkeys
using SplitApplyCombine: group
using StructArrays
using Random
using LinearAlgebra
using Distributions
using UnPack
using LogDensityProblems
using TransformVariables
using DynamicHMC
import ReverseDiff
using MCMCDiagnosticTools
using StatsFuns: logistic
using StatsBase: countmap
using CairoMakie; set_theme!(theme_light())

include("datamodel.jl")
include("decisionmodels.jl")
include("utils.jl")

include("models/binomial_groups_model.jl")
include("models/mixed_membership_model.jl")
include("models/multi_mixed_membership_model.jl")
include("models/multi_mixed_membership_time_model.jl")
include("models/multi_mixed_membership_chairman_model.jl")

include("visualization.jl")

# data handling (types + methods)
export Outcome, Senate, Judge, Decision, Patent
export id, label, senate, outcome, judges, date, patent, cpc, subclass, class, section
export cpc2int

# data import
export DataSource, BPatG

# plotting
export plot_posterior, errorplot!, errorplot, ridgeplot!, ridgeplot

# bayesian modeling
export transformation, sample, paramnames, predict, stats, predict_groups
export DynamicHMCPosterior

export BinomialGroupsModel, MixedMembershipModel 
export MultiMixedMembershipModel, MultiMixedMembershipTimeModel, MultiMixedMembershipChairmanModel

end
