# Resumo dos votos por seção e turno, para as investigações do pré-registro.
#
# Os votos guardam ts_fim no relógio local da urna; o horário de Brasília sai
# do offset do município (para_brasilia). Sem offset (exterior, município sem
# abertura), as contagens por horário ficam NA e as demais são preenchidas.
#
# Rajada: intervalos em segundos entre votos computados consecutivos da mesma
# urna e do mesmo turno. A urna substituída não se liga à nova.

CHAVE_SECAO <- c("uf", "mun", "zona", "secao")

# Meia-noite (UTC ingênuo) do dia de cada turno.
inicio_dia_turno <- function(turno) {
  as.POSIXct(as.Date(names(DIA_TURNO)[match(turno, DIA_TURNO)], "%d/%m/%Y"), tz = "UTC")
}

intervalos_votos <- function(v) {
  v <- data.table::as.data.table(v)[, c(CHAVE_SECAO, "turno", "id_urna", "ts_fim"), with = FALSE]
  data.table::setorderv(v, c(CHAVE_SECAO, "turno", "id_urna", "ts_fim"))
  v[, .(d = as.integer(diff(as.numeric(ts_fim)))), by = c(CHAVE_SECAO, "turno", "id_urna")]$d
}

delta_rajada <- function(contagem) {
  d <- as.integer(names(contagem))
  n <- as.numeric(contagem)[order(d)]
  d <- sort(d)
  d[which(cumsum(n) / sum(n) >= 0.001)[1]]
}

maior_rajada <- function(ts_fim, delta) {
  if (length(ts_fim) == 0L) return(0L)
  abaixo <- diff(sort(as.numeric(ts_fim))) < delta
  r <- rle(abaixo)
  k <- if (any(r$values)) max(r$lengths[r$values]) else 0L
  as.integer(k + 1L)
}

resumir_votos <- function(v, delta) {
  v <- data.table::as.data.table(v)
  base <- inicio_dia_turno(v$turno)
  seg <- as.numeric(para_brasilia(v$ts_fim, v$offset_h)) - as.numeric(base)
  # Colunas auxiliares por referência (a tabela de uma UF é grande demais para
  # copiar); saem ao terminar.
  v[, `:=`(seg_bsb = seg, eh_manual = tipo_hab == "manual")]
  on.exit(v[, c("seg_bsb", "eh_manual") := NULL])
  chave <- c(CHAVE_SECAO, "turno")
  r <- v[, .(votos            = .N,
             manual           = sum(eh_manual),
             sem_bio          = sum(tipo_hab == "sem_biometria"),
             apos_1700        = sum(seg_bsb > 17 * 3600),
             apos_1703        = sum(seg_bsb > 17 * 3600 + 180),
             apos_1600        = sum(seg_bsb >= 16 * 3600),
             manual_apos_1600 = sum(eh_manual & seg_bsb >= 16 * 3600)), by = chave]
  raj <- v[, .(rajada = maior_rajada(ts_fim, delta)), by = c(chave, "id_urna")][
    , .(rajada = max(rajada)), by = chave]
  r <- merge(r, raj, by = chave)
  for (col in c("votos", "manual", "sem_bio", "apos_1700", "apos_1703", "apos_1600", "manual_apos_1600")) {
    data.table::set(r, j = col, value = as.integer(r[[col]]))
  }
  r[]
}
