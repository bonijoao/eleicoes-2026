# Conversão do relógio local da urna para o horário de Brasília.
#
# A votação abre às 8h de Brasília no país todo, então a hora local do primeiro
# voto revela o fuso: offset = 8 - hora(abertura). Usamos a moda por município,
# que resiste a seções que abriram atrasadas; `confianca` é a fração de seções
# na moda. No exterior ("zz") a votação segue o horário local de cada país e o
# offset fica NA de propósito: não convertemos o que não sabemos.
#
# Conferência: o offset tem de estar entre os admissíveis para a UF. Fora disso,
# ou com menos de 3 seções no município, o município fica marcado `suspeito`.

OFFSET_ADMISSIVEL <- list(ac = 2L, am = c(1L, 2L), ro = 1L, rr = 1L, mt = 1L, ms = 1L,
                          pe = c(0L, -1L))  # -1: Fernando de Noronha; demais UFs: 0

fuso_suspeito <- function(uf, offset_h) {
  vapply(seq_along(uf), function(i) {
    if (uf[i] == "zz" || is.na(offset_h[i])) return(NA)
    adm <- OFFSET_ADMISSIVEL[[uf[i]]]
    if (is.null(adm)) adm <- 0L
    !(offset_h[i] %in% adm)
  }, NA)
}

offset_municipio <- function(dt) {
  h <- as.integer(format(dt$abertura_local, "%H", tz = "UTC"))
  x <- data.table::data.table(uf = dt$uf, mun = dt$mun, h = h)[!is.na(h)]
  o <- x[, {
    tab <- table(h)
    moda <- as.integer(names(tab)[which.max(tab)])
    .(offset_h = 8L - moda, n_secoes = .N, confianca = max(tab) / .N)
  }, by = .(uf, mun)]
  o[uf == "zz", offset_h := NA_integer_]
  o[, suspeito := fuso_suspeito(uf, offset_h) | n_secoes < 3L]
  o[uf == "zz", suspeito := NA]
  o[]
}

abertura_destoa <- function(abertura_local, offset_h) {
  (8L - as.integer(format(abertura_local, "%H", tz = "UTC"))) != offset_h
}

para_brasilia <- function(ts_local, offset_h) {
  ts_local + offset_h * 3600
}
