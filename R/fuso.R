# Conversão do relógio local da urna para o horário de Brasília.
#
# A votação abre às 8h de Brasília no país todo, então a hora local de abertura
# revela o fuso: offset = 8 - hora(abertura). Usamos a moda por município, que
# resiste a seções que abriram atrasadas; `confianca` é a fração de seções na
# moda. No exterior ("zz") a votação segue o horário local de cada país e o
# offset fica NA de propósito: não convertemos o que não sabemos.

offset_municipio <- function(dt) {
  h <- as.integer(format(dt$abertura_local, "%H", tz = "UTC"))
  x <- data.table::data.table(uf = dt$uf, mun = dt$mun, h = h)[!is.na(h)]
  o <- x[, {
    tab <- table(h)
    moda <- as.integer(names(tab)[which.max(tab)])
    .(offset_h = 8L - moda, n_secoes = .N, confianca = max(tab) / .N)
  }, by = .(uf, mun)]
  o[uf == "zz", offset_h := NA_integer_]
  o[]
}

para_brasilia <- function(ts_local, offset_h) {
  ts_local + offset_h * 3600
}
