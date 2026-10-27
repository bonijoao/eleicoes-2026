# Diagnóstico descritivo do sinal 3 (rajada), registrado em DESVIOS.md (2026-10-27).
# Não muda nenhuma conta do pré-registro: compara os intervalos entre votos dos
# dois turnos e mostra a hora (de Brasília) em que as rajadas começam.
# Uso: Rscript scripts/07b_rajada_diagnostico.R (antes de scripts/07_voto_espirita.R)
# Requer: dados/processados/{secoes.parquet,votos/} e resultados/rajada_delta.json
# Saída: resultados/rajada_diagnostico.json, resultados/rajada_diagnostico_uf.csv

pkgload::load_all(quiet = TRUE)
library(data.table)

delta <- jsonlite::read_json("resultados/rajada_delta.json")$delta_s
secoes <- as.data.table(arrow::read_parquet("dados/processados/secoes.parquet"))
off <- unique(secoes[!is.na(mun), .(uf, mun, offset_h)])
dir_votos <- "dados/processados/votos"
ufs <- setdiff(sub("^uf=", "", list.files(dir_votos, pattern = "^uf=")), "zz")

partes <- lapply(ufs, function(u) {
  ds <- arrow::open_dataset(file.path(dir_votos, paste0("uf=", u)))
  v <- as.data.table(arrow::Scanner$create(ds, projection = c("mun", "zona", "secao", "id_urna", "ts_fim", "turno"))$ToTable())
  v <- merge(v, off[uf == u, .(mun, offset_h)], by = "mun", all.x = TRUE)
  v[, seg := as.numeric(para_brasilia(ts_fim, offset_h)) - as.numeric(inicio_dia_turno(turno))]
  setorder(v, mun, zona, secao, turno, id_urna, ts_fim)
  g <- c("mun", "zona", "secao", "turno", "id_urna")
  d <- v[, .(d = diff(as.numeric(ts_fim))), by = g]  # como em intervalos_votos
  ini <- v[!is.na(seg), .(seg = inicio_rajadas(seg, delta)), by = g]
  cli::cli_alert_info(u)
  list(int = d[, .(uf = u, intervalos = .N, mediana_s = stats::median(d), abaixo_delta = sum(d < delta)), by = turno],
       cont = d[, .N, by = .(turno, d = pmin(as.integer(d), 600L))],
       hora = ini[, .N, by = .(turno, hora = as.integer(seg %/% 3600))])
})
int <- rbindlist(lapply(partes, `[[`, "int"))
cont <- rbindlist(lapply(partes, `[[`, "cont"))[, .(N = sum(N)), by = .(turno, d)]
hora <- rbindlist(lapply(partes, `[[`, "hora"))[, .(rajadas = sum(N)), by = .(turno, hora)][order(turno, hora)]

mediana_cont <- function(x) x[order(d)][which(cumsum(N) / sum(N) >= 0.5)[1], d]
nac <- int[, .(intervalos = sum(intervalos), abaixo_delta = sum(abaixo_delta)), by = turno][order(turno)]
nac[, `:=`(fracao_abaixo = abaixo_delta / intervalos,
           mediana_s = vapply(turno, function(t) mediana_cont(cont[turno == t]), numeric(1)))]

jsonlite::write_json(list(delta_s = delta, k = 10L, nacional = nac, rajadas_por_hora = hora,
                          gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "America/Sao_Paulo")),
                     "resultados/rajada_diagnostico.json", auto_unbox = TRUE, pretty = TRUE, digits = NA)
fwrite(dcast(int[, .(uf, turno, mediana_s, fracao_abaixo = abaixo_delta / intervalos)], uf ~ turno,
             value.var = c("mediana_s", "fracao_abaixo")), "resultados/rajada_diagnostico_uf.csv")
print(nac)
print(dcast(hora, hora ~ turno, value.var = "rajadas"))
