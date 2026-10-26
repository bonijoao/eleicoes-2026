test_that("url_aux monta o caminho real do TSE", {
  expect_equal(url_aux("3221", "ac", "01074", "0004", "0001"),
    "https://resultados.tse.jus.br/oficial/ele2026/arquivo-urna/3221/dados/ac/01074/0004/0001/p003221-ac-m01074-z0004-s0001-aux.json")
})

test_that("url_indice usa pleito com 6 dígitos", {
  expect_equal(url_indice("3221", "sp"),
    "https://resultados.tse.jus.br/oficial/ele2026/arquivo-urna/3221/config/sp/sp-p003221-cs.json")
})

test_that("url_arquivo inclui o hash como diretório", {
  expect_equal(url_arquivo("3221", "ac", "01074", "0004", "0001", "abc", "o03221ac0107400040001-log.jez"),
    "https://resultados.tse.jus.br/oficial/ele2026/arquivo-urna/3221/dados/ac/01074/0004/0001/abc/o03221ac0107400040001-log.jez")
})

test_that("caminho_cache é estável", {
  expect_equal(caminho_cache("dados/brutos", "3221", "ac", "01074", "0004", "0001", "log"),
    "dados/brutos/3221/ac/01074-0004-0001-log.jez")
  expect_equal(caminho_cache("x", "3221", "ac", "01074", "0004", "0001", c("aux", "bu")),
    c("x/3221/ac/01074-0004-0001-aux.json", "x/3221/ac/01074-0004-0001-bu.dat"))
})
