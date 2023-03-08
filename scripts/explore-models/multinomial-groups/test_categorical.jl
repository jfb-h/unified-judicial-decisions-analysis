using Revise
using Model
using Dictionaries, SplitApplyCombine
using Distributions
using LogExpFunctions: softmax
using FillArrays
using LinearAlgebra
using TransformVariables
using StructArrays
using CairoMakie
using DynamicHMC: ProgressMeterReport
using BenchmarkTools

decisions = loaddata("data/processed/json_augmented");
problem = MixedMembershipCategoricalModel(decisions)
#post = Model.sample(problem, 500, 1; backend=:ReverseDiff, reporter=ProgressMeterReport())