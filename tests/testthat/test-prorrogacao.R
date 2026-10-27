test_that("grupo_decisao: encerramento às 17:03:00 em ponto é grupo A", {
  t <- as.POSIXct(c("2026-10-25 17:03:00", "2026-10-25 17:03:01", NA), tz = "UTC")
  expect_equal(grupo_decisao(t), c("A", "B", NA))
})

test_that("efeito_prorrogacao é a taxa depois das 17h no 2º turno menos a do 1º", {
  expect_equal(efeito_prorrogacao(30, 300, 10, 290), 30 / 300 - 10 / 290)
})

b_ref <- data.table::data.table(
  uf = "aa", mun = rep(c("m1", "m2"), c(5, 4)), aptos = seq(100, 900, 100),
  efeito = c(0.01, 0.02, 0.03, 0.04, 0.05, 0.10, 0.20, 0.30, 0.40))

test_that("taxa_referencia usa o município com 5 ou mais seções B", {
  a <- data.table::data.table(uf = "aa", mun = "m1", zona = "0001", secao = "0001", aptos = 300)
  r <- taxa_referencia(b_ref, a)
  expect_equal(r$r, 0.03)
  expect_equal(r$fonte_r, "municipio")
})

test_that("taxa_referencia cai para UF e quintil de aptos com menos de 5 seções B", {
  a <- data.table::data.table(uf = "aa", mun = "m2", zona = "0001", secao = "0002", aptos = 850)
  r <- taxa_referencia(b_ref, a)
  expect_equal(r$r, 0.35)
  expect_equal(r$fonte_r, "uf_quintil")
})

test_that("taxa_referencia sem seções B na UF fica sem taxa", {
  a <- data.table::data.table(uf = "bb", mun = "m9", zona = "0001", secao = "0003", aptos = 300)
  r <- taxa_referencia(b_ref, a)
  expect_true(is.na(r$r))
  expect_equal(r$fonte_r, "sem_taxa")
})

test_that("teto_voto_perdido calcula bruto, líquido e pior caso", {
  a <- data.table::data.table(uf = "aa", mun = c("m1", "m2", "m1"), aptos = c(100, 200, 100),
                              r = c(0.1, 0.05, NA))
  p <- data.table::data.table(uf = "aa", mun = c("m1", "m2"), p13 = c(0.4, 0.55), p22 = c(0.6, 0.45))
  r95 <- data.table::data.table(uf = "aa", r95 = 0.3)
  t <- teto_voto_perdido(a, p, r95)
  expect_equal(t$bruto, 20)
  expect_equal(t$liquido, 1)
  expect_equal(t$pior_caso, 120)
  expect_equal(t$sem_taxa, 1L)
})
