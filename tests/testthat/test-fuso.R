hora <- function(x) as.POSIXct(paste("2026-10-25", x), tz = "UTC")

test_that("offset vem da moda da hora de abertura por município", {
  dt <- data.table::data.table(
    uf  = c(rep("ac", 4), rep("sp", 2), "zz"),
    mun = c(rep("01074", 4), rep("71072", 2), "29999"),
    abertura_local = hora(c("06:00:01", "06:00:30", "06:01:00", "07:15:00",
                            "08:00:02", "08:00:10", "14:00:00")))
  o <- offset_municipio(dt)
  data.table::setkey(o, uf, mun)
  expect_equal(o[.("ac", "01074"), offset_h], 2L)
  expect_equal(o[.("ac", "01074"), confianca], 0.75)
  expect_equal(o[.("ac", "01074"), n_secoes], 4L)
  expect_equal(o[.("sp", "71072"), offset_h], 0L)
  expect_true(is.na(o[.("zz", "29999"), offset_h]))
})

test_that("para_brasilia soma o offset em horas", {
  expect_equal(format(para_brasilia(hora("15:01:52"), 2L)), "2026-10-25 17:01:52")
  expect_true(is.na(para_brasilia(hora("15:01:52"), NA_integer_)))
})
