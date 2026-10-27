hora <- function(x, dia = "2026-10-25") as.POSIXct(paste(dia, x), tz = "UTC")

votos_sinteticos <- function() {
  data.table::data.table(
    uf = "sp", mun = "00001", zona = "0001", secao = "0001", id_urna = "X", turno = 2L, offset_h = 0L,
    ts_fim = hora(c("16:59:00", "17:00:00", "17:00:01", "17:03:00", "17:03:01")),
    tipo_hab = c("manual", "manual", "biometria", "sem_biometria", "manual"))
}

test_that("resumir_votos conta os votos depois dos cortes com corte estrito", {
  r <- resumir_votos(votos_sinteticos(), delta = 0L)
  expect_equal(nrow(r), 1L)
  expect_equal(r$votos, 5L)
  expect_equal(r$apos_1700, 3L)
  expect_equal(r$apos_1703, 1L)
  expect_equal(r$apos_1600, 5L)
  expect_equal(r$manual_apos_1600, 3L)
  expect_equal(r$manual, 3L)
  expect_equal(r$sem_bio, 1L)
})

test_that("resumir_votos converte para Brasília pelo offset do município", {
  v <- votos_sinteticos()[1][, `:=`(offset_h = 1L, ts_fim = hora("15:59:30"))]
  expect_equal(resumir_votos(v, delta = 0L)$apos_1600, 1L)
})

test_that("resumir_votos usa a data do 1º turno no turno 1", {
  v <- votos_sinteticos()[, `:=`(turno = 1L, ts_fim = ts_fim - 21 * 86400)]
  expect_equal(resumir_votos(v, delta = 0L)$apos_1700, 3L)
})

test_that("resumir_votos sem offset deixa as contas por horário em NA", {
  v <- votos_sinteticos()[, offset_h := NA_integer_]
  r <- resumir_votos(v, delta = 0L)
  expect_true(is.na(r$apos_1700) && is.na(r$apos_1703) && is.na(r$apos_1600) && is.na(r$manual_apos_1600))
  expect_equal(r$votos, 5L)
  expect_equal(r$manual, 3L)
  expect_equal(r$rajada, 1L)
})

test_that("intervalos_votos não liga a urna substituída à nova", {
  v <- data.table::data.table(uf = "sp", mun = "00001", zona = "0001", secao = "0001", turno = 2L,
                              id_urna = c("X", "X", "Y", "Y"),
                              ts_fim = hora(c("10:00:00", "10:00:05", "10:00:06", "10:00:07")))
  expect_equal(intervalos_votos(v), c(5L, 1L))
})

test_that("maior_rajada conta os votos da maior sequência de intervalos abaixo de delta", {
  t <- as.POSIXct(c(0, 2, 4, 6, 100, 101), origin = "1970-01-01", tz = "UTC")
  expect_equal(maior_rajada(t, delta = 3L), 4L)
  expect_equal(maior_rajada(t, delta = 0L), 1L)
  expect_equal(maior_rajada(t[0], delta = 3L), 0L)
})

test_that("delta_rajada é o menor intervalo que acumula 0,1% dos intervalos", {
  expect_equal(delta_rajada(c("0" = 1, "5" = 999, "9" = 9000)), 5L)
  expect_equal(delta_rajada(c("0" = 20, "5" = 9980)), 0L)
})

test_that("inicio_rajadas devolve o início de cada sequência com k votos ou mais", {
  t <- c(0, 2, 4, 6, 100, 101, 102, 200)
  expect_equal(inicio_rajadas(t, delta = 3L, k = 4L), 0)
  expect_equal(inicio_rajadas(t, delta = 3L, k = 3L), c(0, 100))
  expect_equal(inicio_rajadas(t, delta = 3L, k = 5L), numeric(0))
  expect_equal(inicio_rajadas(numeric(0), delta = 3L, k = 2L), numeric(0))
})
