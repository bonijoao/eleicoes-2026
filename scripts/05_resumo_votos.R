# Resumo dos votos por seção e turno, base das investigações 1 e 2.
# Uso: Rscript scripts/05_resumo_votos.R
# Requer: dados/processados/secoes.parquet e dados/processados/votos/ (scripts/03_processar.R)
# Saída: resultados/rajada_delta.json (limiar de rajada, só com o 1º turno)
#        dados/processados/resumo_votos.parquet (uma linha por seção e turno)
#
# O limiar de rajada (δ) sai dos intervalos do 1º turno no Brasil e é gravado
# antes de qualquer voto do 2º turno ser lido, como manda o pré-registro.

pkgload::load_all(quiet = TRUE)
library(data.table)

dir_votos <- "dados/processados/votos"
secoes <- as.data.table(arrow::read_parquet("dados/processados/secoes.parquet"))

# Pré-condição do pré-registro (seção 1).
com_urna <- secoes[categoria != "agregada", .N]
nao_expl <- secoes[categoria == "nao_explicada", .N]
if (nao_expl / com_urna > 0.001) {
  stop(sprintf("nao_explicada = %d de %d seções com urna (%.3f%%), acima de 0,1%%: parar e publicar",
               nao_expl, com_urna, 100 * nao_expl / com_urna))
}
cli::cli_alert_info(sprintf("pré-condição: %d não explicadas em %d seções com urna", nao_expl, com_urna))

ufs <- sub("^uf=", "", list.files(dir_votos, pattern = "^uf="))
ler_votos <- function(uf, turnos, cols) {
  ds <- arrow::open_dataset(file.path(dir_votos, paste0("uf=", uf)))
  filtro <- arrow::Expression$field_ref("turno") == turnos[1]
  if (length(turnos) > 1L) filtro <- filtro | arrow::Expression$field_ref("turno") == turnos[2]
  v <- as.data.table(arrow::Scanner$create(ds, projection = cols, filter = filtro)$ToTable())
  v[, uf := uf]
  v[]
}

# Passada 1: só o 1º turno, sem o exterior.
cont <- rbindlist(lapply(setdiff(ufs, "zz"), function(u) {
  v <- ler_votos(u, 1L, c("mun", "zona", "secao", "id_urna", "ts_fim", "turno"))
  data.table(d = intervalos_votos(v))[, .N, by = d]
}))[, .(N = sum(N)), by = d]
contagem <- setNames(cont$N, cont$d)
delta <- delta_rajada(contagem)
dir.create("resultados", showWarnings = FALSE)
jsonlite::write_json(list(delta_s = delta, intervalos_1t = sum(contagem),
                          abaixo_de_delta = sum(contagem[as.integer(names(contagem)) < delta]),
                          gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "America/Sao_Paulo")),
                     "resultados/rajada_delta.json", auto_unbox = TRUE, pretty = TRUE)
cli::cli_alert_success(sprintf("δ = %d s, sobre %s intervalos do 1º turno", delta, fmt_int(sum(contagem))))

# Passada 2: os dois turnos, todas as UFs.
off <- unique(secoes[!is.na(mun), .(uf, mun, offset_h)])
resumo <- rbindlist(lapply(ufs, function(u) {
  v <- ler_votos(u, 1:2, c("mun", "zona", "secao", "id_urna", "ts_fim", "tipo_hab", "turno"))
  v <- merge(v, off[uf == u], by = c("uf", "mun"), all.x = TRUE)
  r <- resumir_votos(v, delta)
  cli::cli_alert_info(sprintf("%s: %s votos", u, fmt_int(nrow(v))))
  r
}))
arrow::write_parquet(resumo, "dados/processados/resumo_votos.parquet")

# Conferências: votos do log contra o BU nas seções analisadas.
analisadas <- secoes[categoria %in% c("ok", "urna_substituida"), .(uf, mun, zona, secao, comparecimento_bu)]
c2 <- merge(analisadas, resumo[turno == 2L], by = CHAVE_SECAO)
cli::cli_alert_info(sprintf("2º turno, seções analisadas: %s votos no resumo; %s no BU",
                            fmt_int(sum(c2$votos)), fmt_int(sum(c2$comparecimento_bu))))
if (file.exists("dados/indice/bweb_1t.parquet")) {
  v1 <- as.data.table(arrow::read_parquet(sub("secoes.parquet", "validacao_1t.parquet",
                                              "dados/processados/secoes.parquet", fixed = TRUE)))
  b1 <- as.data.table(arrow::read_parquet("dados/indice/bweb_1t.parquet"))
  c1 <- merge(merge(v1[categoria_1t == "ok"], b1, by = CHAVE_SECAO), resumo[turno == 1L], by = CHAVE_SECAO)
  cli::cli_alert_info(sprintf("1º turno, seções ok: %s votos no resumo; %s no BU consolidado",
                              fmt_int(sum(c1$votos)), fmt_int(sum(c1$comparecimento))))
}
print(resumo[, .(secoes = .N, votos = sum(votos), sem_offset = sum(is.na(apos_1700))), by = turno])
