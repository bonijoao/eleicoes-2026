# Testes que reproduzem os achados da revisão de código de 26/10/2026.

linha <- function(h, urna, msg, dia = "25/10/2026") sprintf("%s %s\tINFO\t%s\tVOTA\t%s\tX", dia, h, urna, msg)
no <- function(classe, tag, valor, construido = is.list(valor)) list(classe = classe, construido = construido, tag = tag, valor = valor)

test_that("429 esporádico não esgota o limite quando há blocos limpos entre eles", {
  srv <- webfakes::new_app_process({
    app <- webfakes::new_app(); n <- 0L
    app$get("/b/:i", function(req, res) { n <<- n + 1L
      if (n %in% c(1L, 5L)) res$set_status(429L)$send("calma") else res$send(req$params$i) })
    app
  })
  on.exit(srv$stop())
  d <- withr::local_tempdir()
  r <- baixar_lote(srv$url(sprintf("/b/%d", 1:6)), file.path(d, sprintf("%d.txt", 1:6)),
                   conc = 1L, taxa = 2, pausa_429 = 0.05, max_429 = 1L)
  expect_true(all(r$http == 200L))
})

test_that("429 persistente avisa quantos arquivos ficaram pendentes", {
  srv <- webfakes::new_app_process({
    app <- webfakes::new_app()
    app$get("/sempre", function(req, res) res$set_status(429L)$send("nao"))
    app
  })
  on.exit(srv$stop())
  d <- withr::local_tempdir()
  expect_warning(r <- baixar_lote(srv$url("/sempre"), file.path(d, "x.txt"), pausa_429 = 0.01, max_429 = 2L),
                 "pendentes")
  expect_equal(r$http, 429L)
})

test_that("falha de coleta não se confunde com seção sem arquivos", {
  bu <- fx("ac-01074-0004-0001-bu.dat")
  expect_equal(processar_secao(NA_character_, NA_character_, aux_http = 404L)$secao$categoria, "sem_arquivos")
  expect_equal(processar_secao(NA_character_, NA_character_, aux_http = 429L)$secao$categoria, "coleta_incompleta")
  expect_equal(processar_secao(NA_character_, bu, aux_http = 200L)$secao$categoria, "coleta_incompleta")
  expect_equal(processar_secao(NA_character_, NA_character_, agregada = TRUE, aux_http = NA_integer_)$secao$categoria, "agregada")
})

test_that("estado do hash chega à tabela de seções", {
  r <- processar_secao(fx("sp-64777-0394-0307-log.jez"), fx("sp-64777-0394-0307-bu.dat"),
                       aux_http = 200L, hash_st = "Recebido")
  expect_equal(r$secao$hash_st, "Recebido")
})

test_that("BU informa tipo de BU, de urna e de arquivo", {
  b <- ler_bu(fx("ac-01074-0004-0001-bu.dat"))
  expect_equal(b$tipo_bu, "secao")
  expect_equal(b$tipo_urna, "secao")
  expect_equal(b$tipo_arquivo, "votacaoUE")
})

test_that("BU de Sistema de Apuração não quebra a leitura das datas", {
  sa <- no(2L, 1L, list(no(0L, 2L, as.raw(5)), no(0L, 2L, as.raw(1))))
  d <- ler_dados_secao(sa)
  expect_equal(d$tipo_bu, "sa")
  expect_true(is.na(d$abertura))
})

test_that("BU de apuração por cédula ou contingência tem categoria própria", {
  s <- votos_log(eventos_log(ler_linhas_log(fx("ac-01074-0004-0001-log.jez"))), 2L)
  b <- ler_bu(fx("ac-01074-0004-0001-bu.dat"))
  b_sa <- b; b_sa$tipo_bu <- "sa"; b_sa$tipo_arquivo <- "saManual"
  expect_equal(validar_secao(s, b_sa)$categoria, "apuracao_sa")
  b_ct <- b; b_ct$tipo_urna <- "contingencia"
  expect_equal(validar_secao(s[-1], b_ct)$categoria, "contingencia")
  expect_equal(validar_secao(s, b_ct)$categoria, "ok")
})

test_that("offset de fuso fora do admissível para a UF é suspeito", {
  expect_true(fuso_suspeito("sp", -1L))
  expect_true(fuso_suspeito("ro", 0L))
  expect_false(fuso_suspeito("sp", 0L))
  expect_false(fuso_suspeito("ac", 2L))
  expect_false(fuso_suspeito("am", 1L))
  expect_false(fuso_suspeito("am", 2L))
  expect_false(fuso_suspeito("pe", -1L))
  expect_false(fuso_suspeito("mt", 1L))
  expect_true(is.na(fuso_suspeito("zz", NA_integer_)))
})

test_that("offset_municipio marca suspeito com poucas seções ou valor inadmissível", {
  h <- function(x) as.POSIXct(paste("2026-10-25", x), tz = "UTC")
  dt <- data.table::data.table(uf = c("sp", "sp", "sp", "ro"), mun = c("1", "1", "1", "2"),
                               abertura_local = h(c("08:00:00", "08:00:05", "08:01:00", "08:00:00")))
  o <- offset_municipio(dt); data.table::setkey(o, mun)
  expect_false(o["1", suspeito])
  expect_true(o["2", suspeito])
})

test_that("seção cuja abertura destoa do offset do município é marcada", {
  h <- function(x) as.POSIXct(paste("2026-10-25", x), tz = "UTC")
  ab <- c(h(c("06:00:01", "08:00:00")), as.POSIXct(NA, tz = "UTC"))
  expect_equal(abertura_destoa(ab, c(2L, 2L, 2L)), c(FALSE, TRUE, NA))
})

test_that("habilitado sem voto é separado de tentativa sem voto", {
  l <- c(linha("09:00:00", "1", "Iniciando aplicação - Oficial - 2º turno"),
         linha("09:01:00", "1", "Identificador do eleitor digitado pelo mesário"),
         linha("09:01:10", "1", "Identificador do eleitor digitado pelo mesário"),
         linha("09:01:20", "1", "Eleitor foi habilitado"),
         linha("09:02:00", "1", "Identificador do eleitor digitado pelo mesário"),
         linha("09:02:30", "1", "O voto do eleitor foi computado"))
  v <- votos_log(eventos_log(l), turno = 2L)
  expect_equal(nrow(v), 1L)
  expect_equal(attr(v, "tentativas_sem_voto"), 2L)
  expect_equal(attr(v, "habilitados_sem_voto"), 1L)
})

test_that("encerramento vem da urna que registrou o último voto", {
  l <- c(linha("08:00:00", "A", "Iniciando aplicação - Oficial - 2º turno"),
         linha("08:10:00", "A", "Identificador do eleitor digitado pelo mesário"),
         linha("08:11:00", "A", "O voto do eleitor foi computado"),
         linha("10:00:00", "A", "Inicio do Encerramento"),
         linha("10:30:00", "B", "Iniciando aplicação - Oficial - 2º turno"),
         linha("16:59:00", "B", "Identificador do eleitor digitado pelo mesário"),
         linha("17:04:00", "B", "O voto do eleitor foi computado"),
         linha("17:05:00", "B", "Inicio do Encerramento"))
  e <- eventos_log(l)
  expect_equal(format(encerramento_turno(e, votos_log(e, 2L))), "2026-10-25 17:05:00")
})

test_that("erro inesperado numa seção vira categoria, não derruba o bloco", {
  r <- processar_seguro(NA_character_, NA_character_, .f = function(...) stop("boom"))
  expect_equal(r$secao$categoria, "erro_processamento")
  expect_match(r$secao$erro_log, "boom")
  expect_equal(nrow(r$votos), 0L)
})

test_that("processar_secao diz se o log traz o dia do 1º turno", {
  r <- processar_secao(fx("ac-01074-0004-0001-log.jez"), fx("ac-01074-0004-0001-bu.dat"), aux_http = 200L)
  expect_true(r$secao$log_tem_1t)
  expect_true(is.na(processar_secao(NA_character_, NA_character_)$secao$log_tem_1t))
})

test_that("ler_bweb resume uma linha por seção para presidente", {
  f <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    '"SG_UF";"CD_MUNICIPIO";"NR_ZONA";"NR_SECAO";"CD_CARGO_PERGUNTA";"QT_APTOS";"QT_COMPARECIMENTO";"DS_TIPO_URNA";"NR_VOTAVEL";"QT_VOTOS"',
    '"AC";1074;4;1;1;262;213;"Apurada";13;80',
    '"AC";1074;4;1;1;262;213;"Apurada";22;120',
    '"AC";1074;4;1;7;262;213;"Apurada";55333;6',
    '"AC";1120;8;123;1;300;250;"Apurada";13;100'), f)
  x <- ler_bweb(f)
  expect_equal(nrow(x), 2L)
  expect_equal(x$mun, c("01074", "01120"))
  expect_equal(x$zona, c("0004", "0008"))
  expect_equal(x$secao, c("0001", "0123"))
  expect_equal(x$comparecimento, c(213L, 250L))
  expect_equal(x$uf, c("ac", "ac"))
})
