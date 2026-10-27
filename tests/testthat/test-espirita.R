test_that("kappa_mom é muito grande sem sobredispersão", {
  set.seed(1)
  n <- rep(300L, 2000); y <- stats::rbinom(2000, n, 0.06)
  expect_gt(kappa_mom(y, n, rep(0.06, 2000)), 1000)
})

test_that("kappa_mom recupera a concentração de uma beta-binomial", {
  set.seed(1)
  n <- rep(300L, 2000); y <- stats::rbinom(2000, n, stats::rbeta(2000, 6, 94))
  k <- kappa_mom(y, n, rep(0.06, 2000))
  expect_gt(k, 60)
  expect_lt(k, 160)
})

test_that("taxa_encolhida puxa a taxa da seção para a do município", {
  expect_equal(taxa_encolhida(0, 100, 0.05, 100), 0.025)
})

test_that("taxa_deixa_um_fora usa o município sem a própria seção", {
  expect_equal(taxa_deixa_um_fora(c(2, 4, 6), c(100, 100, 100), c("m", "m", "m")), c(0.05, 0.04, 0.03))
  expect_true(is.na(taxa_deixa_um_fora(3, 100, "s")))
})

test_that("escore_z fica indefinido com esperado zero", {
  expect_true(is.na(escore_z(5, 100, 0)))
  expect_true(is.na(escore_z(5, 100, NA)))
})

test_that("escore_z segue a fórmula do pré-registro", {
  expect_equal(escore_z(20, 100, 0.1), (20 - 10) / sqrt(10 * 0.9))
  expect_equal(escore_z(20, 100, 0.1, phi = 4), (20 - 10) / sqrt(4 * 10 * 0.9))
})

test_that("phi_pearson ignora seções com esperado zero", {
  y <- c(12, 8, 5); n <- c(100, 100, 100); p <- c(0.1, 0.1, 0)
  expect_equal(phi_pearson(y, n, p), ((2 / sqrt(9))^2 + (-2 / sqrt(9))^2) / 1)
})

test_that("sinais aplica os limiares do pré-registro", {
  s <- sinais(z = c(4.1, 4, NA), manual = c(10, 9, 10), manual_apos_1600 = c(8, 9, 1),
              votos = c(100, 100, 100), apos_1600 = c(29, 0, 10), rajada = c(10, 9, NA),
              z_sem = c(NA, 5, 1))
  expect_equal(s$s1, c(TRUE, FALSE, FALSE))
  expect_equal(s$s1b, c(FALSE, TRUE, FALSE))
  expect_equal(s$s2, c(TRUE, FALSE, FALSE))
  expect_equal(s$s3, c(TRUE, FALSE, FALSE))
  expect_equal(s$n_sinais, c(3L, 1L, 0L))
})
