test_that("ler_aux escolhe o hash totalizado e lista log e bu", {
  a <- ler_aux(fx("ac-01074-0004-0001-aux.json"))
  expect_equal(a$hash_st, "Totalizado")
  expect_equal(a$log, "o03221ac0107400040001-log.jez")
  expect_equal(a$bu, "o03221ac0107400040001-bu.dat")
  expect_equal(a$n_hashes, 1L)
})

test_that("aux ausente não tem campo hash, nem por casamento parcial", {
  a <- ler_aux(file.path(tempdir(), "nao-existe-aux.json"))
  expect_null(a[["hash"]])
  expect_true(is.na(a$n_hashes))
})
