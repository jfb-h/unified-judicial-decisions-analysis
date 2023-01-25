using ApproximateGPs
using Distributions
using LinearAlgebra
using LogExpFunctions: logistic, softplus, invsoftplus
using Zygote
using Optim
using CairoMakie

function simulate()
    X = range(0, 23.5; length=48)  # training inputs
    f(x) = 3 * sin(10 + 0.6x) + sin(0.1x) - 1  # latent function
    ps = logistic.(f.(X))  # probabilities at the training inputs
    Y = [rand(Bernoulli(p)) for p in ps]  # observations at the training inputs
    X, Y, f
end

function plot_data!(ax, x, y, f)
    scatter!(ax, x, y)
    lines!(ax, x, logistic ∘ f)
end
function plot_data(x, y, f)
    fig = Figure()
    ax = Axis(fig[1,1])
    plot_data!(ax, x, y, f)
    fig
end

function build_latent_gp(θ)
    variance, lengthscale = softplus.(θ)
    kernel = variance * with_lengthscale(SqExponentialKernel(), lengthscale)
    LatentGP(GP(kernel), BernoulliLikelihood() , 1e-8)
end

function optimize_hyperparams(make_f, x, y; θ_init=invsoftplus.([1.0, 5.0]))
    objective = build_laplace_objective(make_f, x, y)
    grad(θ) = only(Zygote.gradient(objective, θ))
    result = Optim.optimize(objective, grad, θ_init, LBFGS(); inplace=false)
    objective, result
end

function posterior_optimize(x, y)
    objective, optimized = optimize_hyperparams(build_latent_gp, x, y)
    lf_opt = build_latent_gp(optimized.minimizer)
    posterior(LaplaceApproximation(;f_init=objective.cache.f), lf_opt(x), y)
end

function plot_posterior(x, y, f, xgrid, fpost)
    fx = fpost(xgrid, 1e-8)
    fsamples = rand(fx, 50)
    
    fig = Figure(); ax = Axis(fig[1,1])
    foreach(eachcol(fsamples)) do y
        lines!(ax, xgrid, logistic.(y); color=:grey80)
    end
    plot_data!(ax, x, y, f)
    fig
end
