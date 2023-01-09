using Model
using Arrow

decisions = loaddata("data/processed/json_augmented")

# Binomial chairman model

groupfun = (id ∘ first ∘ judges)
model = BinomialGroupsModel(decisions; groupfun)
post = sample(model, 1000, 4)
ess, rhat, treestats = Model.checkconvergence(post)
Arrow.write("data/derivative/inference/posterior_binomial_chairman.arrow", Model._post(post))

# Mixed membership model

model_mm = MixedMembershipModel(decisions)
post_mm = sample(model_mm, 1000, 4)
ess, rhat, treestats = Model.checkconvergence(post)
Arrow.write("data/derivative/inference/posterior_mixed_membership.arrow", Model._post(post_mm))

# Inference

# simple chairman model
let df = Arrow.Table("data/derivative/inference/posterior_binomial_chairman.arrow") |> DataFrame
    fig = Figure(resolution=(1200, 500)); sigma = 2; color = (:black, .2)
    density!(Axis(fig[1,1]; yticksvisible=false, yticklabelsvisible=false), df.μ; color)
    density!(Axis(fig[2,1]; yticksvisible=false, yticklabelsvisible=false), df.σ; color)
    errorplot!(Axis(fig[2,2]), Prediction(), model, df; sigma, subset=findall(model.ns .> 10), ylims=(.6, .9))
    errorplot!(Axis(fig[1,2]), Effect(), model, df; sigma)
    Label(fig[1,1, TopLeft()], "A", fontsize=24); Label(fig[2,1, TopLeft()], "B", fontsize=24)
    Label(fig[1,2, TopLeft()], "C", fontsize=24); Label(fig[2,2, TopLeft()], "D", fontsize=24)
    colsize!(fig.layout, 1, Relative(.3))
    fig
end


# mixed membership model
df = Arrow.Table("data/derivative/inference/posterior_mixed_membership.arrow") |> DataFrame

errorplot(Effect(), df.zt .* df.σt; sigma=1)
errorplot(Effect(), df.zj .* df.σj; sigma=1)
errorplot(Effect(), df.zc .* df.σc; sigma=1)

fig = Figure(resolution=(1000, 600)); errorplot!(Axis(fig[1,1]), Prediction(), model_mm, df; sort=false); fig
