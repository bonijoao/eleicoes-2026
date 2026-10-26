test_that("baixar_lote grava, tenta de novo em 5xx e não insiste em 404", {
  srv <- webfakes::new_app_process({
    app <- webfakes::new_app(); n <- 0L
    app$get("/ok", function(req, res) res$send("conteudo"))
    app$get("/falha2", function(req, res) { n <<- n + 1L
      if (n <= 2L) res$set_status(500L)$send("erro") else res$send("enfim") })
    app$get("/nao", function(req, res) res$set_status(404L)$send("nada"))
    app
  })
  on.exit(srv$stop())
  d <- withr::local_tempdir()
  urls <- srv$url(c("/ok", "/falha2", "/nao"))
  dest <- file.path(d, c("a.txt", "sub/b.txt", "c.txt"))
  r <- baixar_lote(urls, dest, conc = 4L, esperas = c(0.01, 0.01, 0.01, 0.01, 0.01))
  expect_equal(r$http, c(200L, 200L, 404L))
  expect_equal(r$tentativas, c(1L, 3L, 1L))
  expect_equal(readLines(dest[1], warn = FALSE), "conteudo")
  expect_equal(readLines(dest[2], warn = FALSE), "enfim")
  expect_false(file.exists(dest[3]))
  expect_length(list.files(d, pattern = "[.]part$", recursive = TRUE), 0L)
})

test_that("baixar_lote pausa e tenta de novo após 429, e respeita a taxa máxima", {
  srv <- webfakes::new_app_process({
    app <- webfakes::new_app(); n <- 0L
    app$get("/limite", function(req, res) { n <<- n + 1L
      if (n == 1L) res$set_status(429L)$send("calma") else res$send("ok") })
    app$get("/x/:i", function(req, res) res$send(req$params$i))
    app
  })
  on.exit(srv$stop())
  d <- withr::local_tempdir()
  r <- baixar_lote(srv$url("/limite"), file.path(d, "l.txt"), esperas = 0.01, pausa_429 = 0.2)
  expect_equal(r$http, 200L)
  expect_equal(r$tentativas, 2L)

  urls <- srv$url(sprintf("/x/%d", 1:20))
  t <- system.time(r <- baixar_lote(urls, file.path(d, sprintf("x%d.txt", 1:20)), taxa = 10))
  expect_true(all(r$http == 200L))
  expect_gte(t[["elapsed"]], 1.5)
})

test_that("baixar_lote não refaz o que já está em cache", {
  d <- withr::local_tempdir()
  dest <- file.path(d, "x.txt"); writeLines("ja tenho", dest)
  r <- baixar_lote("http://127.0.0.1:1/nunca", dest, esperas = 0.01)
  expect_equal(r$tentativas, 0L)
  expect_equal(r$http, NA_integer_)
  expect_equal(readLines(dest), "ja tenho")
})
