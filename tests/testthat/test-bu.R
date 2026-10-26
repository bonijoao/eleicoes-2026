test_that("der_parse lê comprimento longo", {
  x <- as.raw(c(0x04, 0x81, 0x80, rep(0x41, 128)))
  n <- der_parse(x)
  expect_length(n, 1L)
  expect_false(n[[1]]$construido)
  expect_length(n[[1]]$valor, 128L)
})

test_that("der_parse desce em estruturas construídas e lê tags de contexto", {
  # SEQUENCE { INTEGER 202, [1] IMPLICIT INTEGER 5 }
  x <- as.raw(c(0x30, 0x07, 0x02, 0x02, 0x00, 0xca, 0x81, 0x01, 0x05))
  n <- der_parse(x)[[1]]
  expect_true(n$construido)
  expect_equal(der_int(n$valor[[1]]$valor), 202L)
  expect_equal(n$valor[[2]]$classe, 2L)
  expect_equal(n$valor[[2]]$tag, 1L)
})

test_that("BU AC 01074/0004/0001", {
  b <- ler_bu(fx("ac-01074-0004-0001-bu.dat"))
  expect_equal(b$comparecimento, 202L)
  expect_equal(b$aptos, 262L)
  expect_equal(b$hab, c(biometria = 190L, manual = 11L, sem_biometria = 1L))
  expect_equal(format(b$abertura_local), "2026-10-25 06:00:01")
  expect_equal(format(b$encerramento_local), "2026-10-25 15:01:52")
  expect_equal(format(b$emissao_local), "2026-10-25 15:03:43")
  p <- b$presidente
  expect_equal(p[numero == 13L, votos], 68L)
  expect_equal(p[numero == 22L, votos], 127L)
  expect_equal(p[tipo == "branco", votos], 3L)
  expect_equal(p[tipo == "nulo", votos], 4L)
  expect_equal(sum(p$votos), 202L)
})

test_that("BUs das fixtures de SP somam o comparecimento no cargo de presidente", {
  for (f in c("sp-64777-0394-0307-bu.dat", "sp-64157-0401-0306-bu.dat")) {
    b <- ler_bu(fx(f))
    expect_equal(sum(b$presidente$votos), b$comparecimento)
    expect_equal(sum(b$hab), b$comparecimento)
  }
})
