# Trechos do log do 2º turno das seções com dois ou mais sinais, para o exame
# caso a caso da investigação 2. Sem análise automática: o exame é feito lendo
# cada arquivo e vai para resultados/voto_espirita_casos.md.
# Uso: Rscript scripts/08_casos.R
# Requer: resultados/voto_espirita_sinais.csv, resultados/rajada_delta.json,
#         dados/processados/{secoes,resumo_votos}.parquet e os logs em dados/brutos
# Saída: dados/casos/<uf>-<mun>-<zona>-<secao>.txt

pkgload::load_all(quiet = TRUE)
library(data.table)

delta  <- jsonlite::read_json("resultados/rajada_delta.json")$delta_s
sinais <- fread("resultados/voto_espirita_sinais.csv", colClasses = list(character = c("mun", "zona", "secao")))
secoes <- as.data.table(arrow::read_parquet("dados/processados/secoes.parquet"))
resumo <- as.data.table(arrow::read_parquet("dados/processados/resumo_votos.parquet"))
casos <- sinais[turno == 2L & n_sinais >= 2L]
dir.create("dados/casos", showWarnings = FALSE, recursive = TRUE)

# Mensagens do ciclo de cada voto: contadas, não listadas.
CICLO <- c("Identificador do eleitor digitado pelo mesário", "Solicita digital", "Eleitor foi habilitado",
           "O voto do eleitor foi computado", "Solicitação de dado pessoal do eleitor para habilitação manual",
           "Voto confirmado para", "Tecla indevida", "Aguardando digitação do título",
           "Título digitado pelo mesário", "Digital", "Dedo", "Captura", "Eleitor")
do_ciclo <- function(msg) Reduce(`|`, lapply(CICLO, function(p) startsWith(msg, p)))

for (i in seq_len(nrow(casos))) {
  k <- casos[i]
  sec <- secoes[uf == k$uf & mun == k$mun & zona == k$zona & secao == k$secao]
  rs <- resumo[uf == k$uf & mun == k$mun & zona == k$zona & secao == k$secao][order(turno)]
  e <- eventos_log(ler_linhas_log(caminho_cache("dados/brutos", "3221", k$uf, k$mun, k$zona, k$secao, "log")))
  e2 <- e[turno %in% 2L]
  v <- votos_log(e, 2L)
  setorder(v, id_urna, ts_fim)
  raj <- v[, .(ini = inicio_rajadas(ts_fim, delta)), by = id_urna]
  v[, d := c(NA, diff(as.numeric(ts_fim))), by = id_urna]
  v[, rapido := !is.na(d) & d < delta]
  v[, em_rajada := rapido | shift(rapido, -1L, fill = FALSE), by = id_urna]
  v[, run := rleid(em_rajada), by = id_urna]
  v[, tam := .N, by = .(id_urna, run)]
  fora <- e2[!do_ciclo(msg)]
  fora[, msg_curta := substr(msg, 1, 90)]

  txt <- c(
    sprintf("%s %s/%s/%s  sinais: %s  z = %.2f  z_sem = %.2f", k$uf, k$mun, k$zona, k$secao,
            paste(c("1", "1b", "2", "3")[c(k$s1, k$s1b, k$s2, k$s3)], collapse = " "), k$z, k$z_sem),
    sprintf("categoria: %s  offset_h: %s  urnas no 2T: %s", sec$categoria, sec$offset_h,
            paste(unique(v$id_urna), collapse = ", ")),
    "", "resumo por turno (votos, manual, sem_bio, apos_1600, manual_apos_1600, rajada):",
    capture.output(print(rs[, .(turno, votos, manual, sem_bio, apos_1600, manual_apos_1600, rajada)])),
    "", "habilitação por hora local no 2T:",
    capture.output(print(dcast(v[, .N, by = .(h = as.integer(format(ts_fim, "%H")), tipo_hab)],
                               h ~ tipo_hab, value.var = "N", fill = 0L))),
    "", "níveis do log no 2T:", capture.output(print(e2[, .N, by = nivel])),
    "", "mensagens fora do ciclo do voto no 2T (contagem, primeira e última hora):",
    capture.output(print(fora[, .(n = .N, primeira = format(min(ts_local), "%H:%M:%S"),
                                  ultima = format(max(ts_local), "%H:%M:%S")), by = .(nivel, msg_curta)],
                         nrows = 200)),
    "", sprintf("rajadas (10+ votos com intervalos < %d s): início em %s", delta,
                paste(format(as.POSIXct(raj$ini, origin = "1970-01-01", tz = "UTC"), "%H:%M:%S"), collapse = ", ")),
    capture.output(print(v[em_rajada & tam >= 10L, .(id_urna, ts_ini = format(ts_ini, "%H:%M:%S"),
                                                     ts_fim = format(ts_fim, "%H:%M:%S"), d, tipo_hab, n_tentativas)],
                         nrows = 500))
  )
  writeLines(txt, sprintf("dados/casos/%s-%s-%s-%s.txt", k$uf, k$mun, k$zona, k$secao), useBytes = TRUE)
}
cli::cli_alert_success(sprintf("%d casos em dados/casos", nrow(casos)))
