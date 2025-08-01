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
using FillArrays
using Random
using LinearAlgebra
using ThreadsX

using Distributions
using LogDensityProblems
using LogDensityProblemsAD
using TransformVariables
using TransformedLogDensities
using DynamicHMC
using DynamicHMC.Diagnostics
using MCMCDiagnosticTools
using InferenceObjects

using StatsFuns: logistic
using LogExpFunctions: softmax
using StatsBase: countmap
import ReverseDiff

set_theme!(theme_light())

include("datamodel.jl")
include("decisionmodels.jl")
include("utils.jl")
include("inferencedata.jl")
include("loo.jl")

include("models/binomial_groups_model.jl")
include("models/mixed_membership_model.jl")
include("models/categorical_model.jl")
include("models/categorical_model_final.jl")
include("models/judgesonly_model_final.jl")

include("visualization.jl")

# data handling (types + methods)
export Outcome, Board, Judge, Decision, Patent
export id, label, board, outcome, judges, date
export patent, cpc, subclass, class, section, patentage, office
export cpc2int

# data import
export loaddata

# bayesian modeling
export transformation, sample, paramnames
export predict, stats, empirical
export getsamples
export DynamicHMCPosterior

export BPatGModel, JudgesOnly

end
