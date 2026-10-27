# Investigação 1 do pré-registro: a prorrogação até as 19h.
#
# Grupo A: seção encerrada até a decisão (17h03 de Brasília); grupo B: depois.
# O efeito da prorrogação numa seção B é a taxa de votos depois das 17h00 por
# eleitor apto no 2º turno menos a mesma taxa no 1º turno. O teto do voto
# perdido aplica às seções A a mediana desse efeito nas B parecidas.

DECISAO_ZANIN <- as.POSIXct("2026-10-25 17:03:00", tz = "UTC")
MARGEM_OFICIAL <- 4430191L

grupo_decisao <- function(encerramento_bsb) {
  data.table::fifelse(encerramento_bsb <= DECISAO_ZANIN, "A", "B", na = NA_character_)
}

efeito_prorrogacao <- function(apos_1700_2t, aptos_2t, apos_1700_1t, aptos_1t) {
  apos_1700_2t / aptos_2t - apos_1700_1t / aptos_1t
}

# Quintil de aptos dentro da UF, com os cortes das seções B da UF; valores fora
# da faixa vão para o quintil da ponta.
quintil_aptos <- function(x, cortes) {
  findInterval(x, cortes, rightmost.closed = TRUE, all.inside = TRUE)
}

taxa_referencia <- function(b, a) {
  b <- data.table::as.data.table(b); a <- data.table::copy(data.table::as.data.table(a))
  por_mun <- b[, .(r_mun = stats::median(efeito), n_b = .N), by = .(uf, mun)]
  cortes <- b[, .(cortes = list(unique(stats::quantile(aptos, 0:5 / 5, names = FALSE)))), by = uf]
  b[cortes, q := quintil_aptos(aptos, i.cortes[[1]]), on = "uf", by = .EACHI]
  por_q <- b[, .(r_q = stats::median(efeito)), by = .(uf, q)]
  a[, `:=`(q = NA_integer_, r_mun = NA_real_, n_b = NA_integer_, r_q = NA_real_)]
  a[cortes, q := quintil_aptos(aptos, i.cortes[[1]]), on = "uf", by = .EACHI]
  a[por_mun, `:=`(r_mun = i.r_mun, n_b = i.n_b), on = c("uf", "mun")]
  a[por_q, r_q := i.r_q, on = c("uf", "q")]
  a[, fonte_r := data.table::fcase(!is.na(n_b) & n_b >= 5L, "municipio",
                                   !is.na(r_q), "uf_quintil",
                                   default = "sem_taxa")]
  a[, r := data.table::fcase(fonte_r == "municipio", r_mun, fonte_r == "uf_quintil", r_q,
                             default = NA_real_)]
  a[, c("q", "r_mun", "n_b", "r_q") := NULL]
  a[]
}

# Seções A sem taxa não entram no bruto nem no líquido; no pior caso entram
# todas as que têm o percentil 95 da UF.
teto_voto_perdido <- function(a, p, r95_uf) {
  x <- merge(merge(data.table::as.data.table(a), p, by = c("uf", "mun"), all.x = TRUE),
             r95_uf, by = "uf", all.x = TRUE)
  list(bruto     = x[!is.na(r), sum(aptos * r)],
       liquido   = x[!is.na(r), sum(aptos * r * (p22 - p13))],
       pior_caso = x[!is.na(r95), sum(aptos * r95)],
       sem_taxa  = x[is.na(r), .N])
}
