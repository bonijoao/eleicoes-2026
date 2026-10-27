test_that("md_tab monta tabela Markdown", {
  expect_equal(md_tab(data.frame(a = 1:2, b = c("x", "y"))),
               c("| a | b |", "| --- | --- |", "| 1 | x |", "| 2 | y |"))
})

test_that("link_secao aponta para o aux.json da seção no TSE", {
  expect_true(startsWith(link_secao("ac", "01074", "0004", "0001"),
                         "[ac 01074/0004/0001](https://resultados.tse.jus.br/"))
})

test_that("fmt_int usa ponto como separador de milhar", {
  expect_equal(fmt_int(4430191L), "4.430.191")
  expect_equal(fmt_int(c(7L, 1000L)), c("7", "1.000"))
})
