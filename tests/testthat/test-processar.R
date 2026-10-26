test_that("processar_secao resume a seção do AC e devolve os votos dos dois turnos", {
  r <- processar_secao(fx("ac-01074-0004-0001-log.jez"), fx("ac-01074-0004-0001-bu.dat"))
  s <- r$secao
  expect_equal(nrow(s), 1L)
  expect_equal(s$votos_log, 202L)
  expect_equal(s$votos_log_1t, 213L)
  expect_equal(s$comparecimento_bu, 202L)
  expect_equal(s$categoria, "ok")
  expect_equal(c(s$hab_bio, s$hab_manual, s$hab_sem), c(190L, 11L, 1L))
  expect_equal(c(s$pres_13, s$pres_22, s$brancos, s$nulos), c(68L, 127L, 3L, 4L))
  expect_equal(format(s$abertura_local), "2026-10-25 06:00:01")
  expect_equal(format(s$encerramento_local), "2026-10-25 15:01:52")
  expect_equal(format(s$encerramento_log_local), "2026-10-25 15:03:41")
  expect_equal(sort(unique(r$votos$turno)), c(1L, 2L))
  expect_equal(nrow(r$votos), 202L + 213L)
})

test_that("processar_secao sem arquivos não quebra", {
  r <- processar_secao(NA_character_, NA_character_)
  expect_equal(r$secao$categoria, "sem_arquivos")
  expect_equal(nrow(r$votos), 0L)
})

test_that("processar_secao com log corrompido registra o erro e segue", {
  f <- tempfile(fileext = ".jez"); writeBin(as.raw(1:50), f)
  r <- processar_secao(f, fx("ac-01074-0004-0001-bu.dat"))
  expect_equal(r$secao$categoria, "bu_sem_log")
  expect_false(is.na(r$secao$erro_log))
})
