secao_fx <- function(id) {
  e <- eventos_log(ler_linhas_log(fx(paste0(id, "-log.jez"))))
  list(votos = votos_log(e, 2L), bu = ler_bu(fx(paste0(id, "-bu.dat"))))
}

test_that("AC: log e BU batem exatamente", {
  s <- secao_fx("ac-01074-0004-0001")
  v <- validar_secao(s$votos, s$bu)
  expect_equal(v$categoria, "ok")
  expect_equal(v$dif, 0L)
})

test_that("SP com log aninhado: bate, com ou sem urna substituída", {
  for (id in c("sp-64777-0394-0307", "sp-64157-0401-0306")) {
    s <- secao_fx(id)
    v <- validar_secao(s$votos, s$bu)
    expect_true(v$categoria %in% c("ok", "urna_substituida"), label = id)
    expect_equal(v$dif, 0L, label = id)
  }
})

test_that("seção sem arquivos e BU sem log têm categoria própria", {
  expect_equal(validar_secao(NULL, NULL)$categoria, "sem_arquivos")
  b <- ler_bu(fx("ac-01074-0004-0001-bu.dat"))
  expect_equal(validar_secao(NULL, b)$categoria, "bu_sem_log")
})

test_that("seção agregada sem arquivos é explicada", {
  expect_equal(validar_secao(NULL, NULL, agregada = TRUE)$categoria, "agregada")
})

test_that("diferença de contagem ou de habilitação é não explicada", {
  s <- secao_fx("ac-01074-0004-0001")
  v <- validar_secao(s$votos[-1], s$bu)
  expect_equal(v$categoria, "nao_explicada")
  expect_equal(v$dif, -1L)
  troca <- data.table::copy(s$votos)
  troca[tipo_hab == "manual", tipo_hab := "biometria"]
  expect_equal(validar_secao(troca, s$bu)$categoria, "nao_explicada")
})

test_that("dois id_urna com votos e soma certa é urna substituída", {
  s <- secao_fx("ac-01074-0004-0001")
  v2 <- data.table::copy(s$votos)
  v2[1:10, id_urna := "99999999"]
  expect_equal(validar_secao(v2, s$bu)$categoria, "urna_substituida")
})
