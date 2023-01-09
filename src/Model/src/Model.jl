module Model

using Reexport: @reexport

@reexport using Statistics
@reexport using DataFrames
@reexport using CairoMakie

using JSON3
using Dates
using Dictionaries: Dictionary, dictionary, sortkeys
using SplitApplyCombine: group
using StructArrays
using Random
using LinearAlgebra
using Distributions
import ReverseDiff
using LogDensityProblems
using TransformVariables
using TransformedLogDensities
using DynamicHMC
using DynamicHMC.Diagnostics
using MCMCDiagnosticTools
using StatsFuns: logistic
using StatsBase: countmap

set_theme!(theme_light())

include("datamodel.jl")
include("decisionmodels.jl")
include("utils.jl")

include("models/binomial_groups_model.jl")
include("models/mixed_membership_model.jl")

include("visualization.jl")

# data handling (types + methods)
export Outcome, Senate, Judge, Decision, Patent
export id, label, senate, outcome, judges, date, patent, cpc, subclass, class, section
export cpc2int

# data import
export loaddata

# plotting
export plot_posterior, errorplot!, errorplot, ridgeplot!, ridgeplot

# bayesian modeling
export transformation, sample, paramnames, predict, stats, predict_groups, empirical
export DynamicHMCPosterior

export BinomialGroupsModel, MixedMembershipModel 

end
