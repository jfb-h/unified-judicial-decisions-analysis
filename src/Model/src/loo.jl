# function getsamples(post)
#   res = getfield(post, :res)
#   pmat = stack_posterior_matrices(res)
#   permutedims(pmat, (1, 3, 2))
# end

# data = [(; outcome=o, js=j) for (o, j) in zip(problem.outcomes, problem.js)]

# pll = pointwise_log_likelihoods(ll, samples, collect(data); splat=false)

# psis_loo(pll)
