log_ac <- function() ler_linhas_log(fx("ac-01074-0004-0001-log.jez"))

test_that("ler_linhas_log descompacta, converte de Latin-1 e acha a primeira linha", {
  l <- log_ac()
  expect_gt(length(l), 9000L)
  expect_equal(l[1], "23/09/2026 13:33:03\tINFO\t02260684\tLOGD\tInício das operações do logd\tAD2D27064D9A2575")
})

test_that("AC 01074/0004/0001: 2º turno bate com a contagem conhecida", {
  v <- votos_log(eventos_log(log_ac()), turno = 2L)
  expect_equal(nrow(v), 202L)
  expect_equal(as.list(table(v$tipo_hab))[c("biometria", "manual", "sem_biometria")],
               list(biometria = 190L, manual = 11L, sem_biometria = 1L))
  expect_true(all(format(v$ts_fim, "%Y-%m-%d") == "2026-10-25"))
})

test_that("AC: 1º turno está no mesmo log e tem 213 votos", {
  e <- eventos_log(log_ac())
  expect_equal(nrow(votos_log(e, turno = 1L)), 213L)
})

test_that("log aninhado é lido inteiro e sem linhas duplicadas", {
  l <- ler_linhas_log(fx("sp-64777-0394-0307-log.jez"))
  expect_false(anyDuplicated(l) > 0)
  e <- eventos_log(l)
  expect_gt(length(unique(e$id_urna)), 1L)
})

test_that("sequência sem voto computado não vira voto", {
  l <- c(
    "25/10/2026 09:00:00\tINFO\t1\tVOTA\tIniciando aplicação - Oficial - 2º turno\tX",
    "25/10/2026 09:01:00\tINFO\t1\tVOTA\tIdentificador do eleitor digitado pelo mesário\tX",
    "25/10/2026 09:02:00\tINFO\t1\tVOTA\tIdentificador do eleitor digitado pelo mesário\tX",
    "25/10/2026 09:03:00\tINFO\t1\tVOTA\tO voto do eleitor foi computado\tX")
  v <- votos_log(eventos_log(l), turno = 2L)
  expect_equal(nrow(v), 1L)
  expect_equal(attr(v, "incompletos"), 1L)
})

test_that("urna ligada na véspera e não reiniciada conta os votos do dia do turno", {
  # caso real: pr 74810/0009/0091, ligada em 24/10 às 9h18 e mantida na tomada
  l <- c(
    "24/10/2026 09:19:04\tINFO\t1\tGAP\tIniciando aplicação - 2º turno\tX",
    "24/10/2026 09:20:31\tINFO\t1\tVOTA\tIniciando aplicação - 2º turno\tX",
    "24/10/2026 23:51:08\tINFO\t1\tVOTA\tQuantidade de memória usada [362.4 MB]\tX",
    "25/10/2026 08:01:00\tINFO\t1\tVOTA\tIdentificador do eleitor digitado pelo mesário\tX",
    "25/10/2026 08:02:00\tINFO\t1\tVOTA\tO voto do eleitor foi computado\tX")
  v <- votos_log(eventos_log(l), turno = 2L)
  expect_equal(nrow(v), 1L)
})

test_that("voto em dia que não é de turno não conta", {
  l <- c(
    "24/10/2026 09:20:31\tINFO\t1\tVOTA\tIniciando aplicação - 2º turno\tX",
    "24/10/2026 10:01:00\tINFO\t1\tVOTA\tIdentificador do eleitor digitado pelo mesário\tX",
    "24/10/2026 10:02:00\tINFO\t1\tVOTA\tO voto do eleitor foi computado\tX")
  expect_equal(nrow(votos_log(eventos_log(l), turno = 2L)), 0L)
})

test_that("tentativas de digital e manual são contadas por voto", {
  l <- c(
    "25/10/2026 09:00:00\tINFO\t1\tVOTA\tIniciando aplicação - Oficial - 2º turno\tX",
    "25/10/2026 09:01:00\tINFO\t1\tVOTA\tIdentificador do eleitor digitado pelo mesário\tX",
    "25/10/2026 09:01:05\tINFO\t1\tVOTA\tSolicita digital. Tentativa [1] de [4]\tX",
    "25/10/2026 09:01:09\tINFO\t1\tVOTA\tSolicita digital. Tentativa [4] de [4]\tX",
    "25/10/2026 09:01:20\tINFO\t1\tVOTA\tSolicitação de dado pessoal do eleitor para habilitação manual\tX",
    "25/10/2026 09:03:00\tINFO\t1\tVOTA\tO voto do eleitor foi computado\tX")
  v <- votos_log(eventos_log(l), turno = 2L)
  expect_equal(v$tipo_hab, "manual")
  expect_equal(v$n_tentativas, 4L)
  expect_equal(format(v$ts_ini), "2026-10-25 09:01:00")
})
