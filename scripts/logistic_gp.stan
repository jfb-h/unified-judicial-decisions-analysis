data {
  int<lower=1> N;
  array[N] real x;
  array[N] int<lower=0, upper=1> y;
  int<lower=1> Npred;
  array[Npred] real xpred;
}
transformed data {
  real delta = 1e-9;
}
parameters {
  real<lower=0> rho;
  real<lower=0> alpha;
  real a;
  vector[N] eta;
}
transformed parameters {
  vector[N] f;
  {
    matrix[N, N] L_K;
    matrix[N, N] K = cov_exp_quad(x, alpha, rho);

    // diagonal elements
    for (n in 1:N)
      K[n, n] = K[n, n] + delta;

    L_K = cholesky_decompose(K);
    f = L_K * eta;
  }
}
model {
  rho ~ inv_gamma(5, 5);
  alpha ~ std_normal();
  a ~ std_normal();
  eta ~ std_normal();

  y ~ bernoulli_logit(a + f);
}
generated quantities {
  vector[Npred] phat;
  
  {
    matrix[Npred, Npred] L_K;
    matrix[Npred, Npred] K = cov_exp_quad(xpred, alpha, rho);

    // diagonal elements
    for (n in 1:Npred)
      K[n, n] = K[n, n] + delta;

    L_K = cholesky_decompose(K);
    phat = a + L_K * eta;
  }
}
