test_that("ler_indice_secoes achata municípios, zonas e seções preservando zeros", {
  js <- '{ "cdp": "3221", "abr": [ { "cd": "ac", "mu": [
    { "cd": "01074", "zon": [ { "cd": "0004", "sec": [ { "ns": "0001" }, { "ns": "0005" } ] } ] },
    { "cd": "01120", "zon": [ { "cd": "0008", "sec": [ { "ns": "0123" } ] } ] } ] } ] }'
  f <- tempfile(fileext = ".json"); writeLines(js, f)
  x <- ler_indice_secoes(f)
  expect_s3_class(x, "data.table")
  expect_equal(names(x), c("uf", "mun", "zona", "secao"))
  expect_equal(x$uf, rep("ac", 3))
  expect_equal(x$mun, c("01074", "01074", "01120"))
  expect_equal(x$secao, c("0001", "0005", "0123"))
})
