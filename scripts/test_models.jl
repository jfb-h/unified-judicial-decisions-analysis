include("../src/Model/Model.jl")
using .Model

decisions = loaddata("data/processed/json_augmented")

# Binomial chairman model

groupfun = (id ∘ first ∘ judges)
model = BinomialGroupsModel(decisions; groupfun)
post = sample(model, 1000, 2)
ess, rhat, treestats = Model.checkconvergence(post)

# Mixed membership model

model_mm = MixedMembershipModel(decisions)
post = sample(model_mm, 1000, 4)