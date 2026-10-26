# Processa todas as seções coletadas: uma linha por seção e uma linha por voto.
# Uso: Rscript scripts/03_processar.R --pleito 3221 [--amostra] [--workers 20]
# Requer: dados/indice/status_<pleito>[_amostra].parquet (scripts/02_coletar.R)
# Saída (em dados/processados[/amostra]/):
#   secoes.parquet                      uma linha por seção, com offset de fuso
#   votos/uf=<uf>/parte-<k>.parquet     uma linha por voto (horário local da urna)
# O horário de Brasília dos votos sai da junção com secoes.offset_h (ver
# R/consulta.R), para não regravar centenas de milhões de linhas.

pkgload::load_all(quiet = TRUE)
library(data.table)

a <- commandArgs(trailingOnly = TRUE)
arg <- function(nome, padrao = NULL) { i <- match(paste0("--", nome), a); if (is.na(i)) padrao else a[i + 1] }
pleito  <- arg("pleito", "3221")
amostra <- "--amostra" %in% a
workers <- as.integer(arg("workers", "20"))
sufixo  <- if (amostra) "_amostra" else ""
saida   <- if (amostra) "dados/processados/amostra" else "dados/processados"
raiz    <- "dados/brutos"

status <- as.data.table(arrow::read_parquet(sprintf("dados/indice/status_%s%s.parquet", pleito, sufixo)))
status[, `:=`(log_path = caminho_cache(raiz, pleito, uf, mun, zona, secao, "log"),
              bu_path  = caminho_cache(raiz, pleito, uf, mun, zona, secao, "bu"))]
status[log_ok == FALSE, log_path := NA_character_]
status[bu_ok == FALSE, bu_path := NA_character_]

unlink(file.path(saida, "votos"), recursive = TRUE)
dir.create(file.path(saida, "votos"), recursive = TRUE, showWarnings = FALSE)

# Blocos de até 200 seções da mesma UF; cada worker grava os votos do seu bloco.
status[, bloco := paste(uf, (seq_len(.N) - 1L) %/% 200L, sep = "-"), by = uf]
blocos <- split(status[, .(uf, mun, zona, secao, log_path, bu_path, agregada = !is.na(secao_principal))], status$bloco)

mirai::daemons(workers)
mirai::everywhere(pkgload::load_all(raiz_pacote, quiet = TRUE), raiz_pacote = getwd())
t0 <- Sys.time()
tarefas <- lapply(seq_along(blocos), function(k) list(k = k, b = blocos[[k]]))
res <- mirai::mirai_map(tarefas, function(t, saida) {
  k <- t$k; b <- t$b
  r <- lapply(seq_len(nrow(b)), function(i) processar_secao(b$log_path[i], b$bu_path[i], b$agregada[i]))
  sec <- data.table::rbindlist(lapply(r, `[[`, "secao"))
  sec <- cbind(b[, .(uf, mun, zona, secao)], sec)
  vot <- data.table::rbindlist(lapply(seq_along(r), function(i) {
    v <- r[[i]]$votos
    if (nrow(v)) cbind(b[i, .(uf, mun, zona, secao)], v) else NULL
  }))
  if (nrow(vot)) {
    d <- file.path(saida, "votos", paste0("uf=", b$uf[1]))
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    arrow::write_parquet(vot[, !"uf"], file.path(d, sprintf("parte-%05d.parquet", k)))
  }
  sec
}, .args = list(saida = saida))[.progress]
mirai::daemons(0)

erros <- Filter(mirai::is_error_value, res)
if (length(erros)) { print(erros[[1]]); stop(length(erros), " blocos com erro") }
secoes <- rbindlist(res)
off <- offset_municipio(secoes[!is.na(abertura_local), .(uf, mun, abertura_local)])
secoes <- merge(secoes, off[, .(uf, mun, offset_h, confianca_offset = confianca)],
                by = c("uf", "mun"), all.x = TRUE)
for (col in c("abertura", "encerramento", "encerramento_log", "ultimo_voto")) {
  secoes[, (paste0(col, "_bsb")) := para_brasilia(get(paste0(col, "_local")), offset_h)]
}
arrow::write_parquet(secoes, file.path(saida, "secoes.parquet"))

cli::cli_alert_success(sprintf("%d seções em %.1f min", nrow(secoes),
                               as.numeric(difftime(Sys.time(), t0, units = "mins"))))
print(secoes[, .N, by = categoria][order(-N)])
