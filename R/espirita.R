# Investigação 2 do pré-registro: "voto espírita".
#
# A taxa de habilitação manual esperada de uma seção no 2º turno vem do 1º turno
# da mesma seção, encolhida para a taxa do município (Bayes empírico
# beta-binomial, concentração κ por UF pelo método dos momentos). O escore z
# compara o observado com o esperado, com a sobredispersão φ nacional.
# Contas fixadas em DESVIOS.md (2026-10-27).

kappa_mom <- function(y, n, m) {
  ok <- n > 1 & m > 0 & m < 1 & !is.na(m)
  x <- y[ok] / n[ok]; n <- n[ok]; m <- m[ok]
  rho <- mean(((x - m)^2 / (m * (1 - m)) - 1 / n) / (1 - 1 / n))
  rho <- min(max(rho, 1e-6), 0.999)
  1 / rho - 1
}

taxa_encolhida <- function(y1, n1, m_mun, kappa) (y1 + kappa * m_mun) / (n1 + kappa)

taxa_deixa_um_fora <- function(y1, n1, grupo) {
  sy <- stats::ave(y1, grupo, FUN = sum); sn <- stats::ave(n1, grupo, FUN = sum)
  r <- (sy - y1) / (sn - n1)
  r[!is.finite(r)] <- NA_real_
  r
}

escore_z <- function(y2, n2, p, phi = 1) {
  e <- n2 * p
  z <- (y2 - e) / sqrt(phi * e * (1 - p))
  z[is.na(p) | e <= 0 | p >= 1] <- NA_real_
  z
}

phi_pearson <- function(y2, n2, p) {
  e <- n2 * p
  ok <- !is.na(p) & e > 0 & p < 1
  sum(((y2[ok] - e[ok]) / sqrt(e[ok] * (1 - p[ok])))^2) / (sum(ok) - 1)
}

sinais <- function(z, manual, manual_apos_1600, votos, apos_1600, rajada, z_sem = NA) {
  s <- data.table::data.table(
    s1  = (z > 4) %in% TRUE,
    s1b = (z_sem > 4) %in% TRUE,
    s2  = (manual >= 10 & (manual_apos_1600 / manual - apos_1600 / votos) > 0.5) %in% TRUE,
    s3  = (rajada >= 10) %in% TRUE)
  s[, n_sinais := as.integer(s1 + s1b + s2 + s3)]
  s[]
}
