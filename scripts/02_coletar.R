# Baixa aux.json, log e BU de cada seção, com cache e retomada.
# Uso: Rscript scripts/02_coletar.R --pleito 3221 --ufs todas [--amostra 2000] [--taxa 20]
#      --ufs aceita lista separada por vírgula (ex.: ac,sp)
# Requer: dados/indice/secoes_<pleito>.parquet (scripts/01_indice.R)
# Saída: dados/brutos/<pleito>/<uf>/... e dados/indice/status_<pleito>.parquet

pkgload::load_all(quiet = TRUE)
library(data.table)

arg <- function(nome, padrao = NULL) {
  a <- commandArgs(trailingOnly = TRUE); i <- match(paste0("--", nome), a)
  if (is.na(i)) padrao else a[i + 1]
}
pleito  <- arg("pleito", "3221")
ufs     <- arg("ufs", "todas")
amostra <- arg("amostra")
taxa    <- as.numeric(arg("taxa", "20"))   # requisições por segundo
lote    <- 5000L
raiz    <- "dados/brutos"

secoes <- as.data.table(arrow::read_parquet(sprintf("dados/indice/secoes_%s.parquet", pleito)))
if (ufs != "todas") secoes <- secoes[uf %in% strsplit(ufs, ",")[[1]]]
if (!is.null(amostra)) { set.seed(2026); secoes <- secoes[sort(sample(.N, as.integer(amostra)))] }
# Seção agregada não tem urna nem arquivos: entra no status sem requisição.
agregadas <- secoes[!is.na(secao_principal)]
secoes <- secoes[is.na(secao_principal)]

status <- list()
blocos <- split(seq_len(nrow(secoes)), ceiling(seq_len(nrow(secoes)) / lote))
t0 <- Sys.time()
for (b in seq_along(blocos)) {
  s <- secoes[blocos[[b]]]
  aux_dest <- s[, caminho_cache(raiz, pleito, uf, mun, zona, secao, "aux")]
  r_aux <- baixar_lote(s[, url_aux(pleito, uf, mun, zona, secao)], aux_dest, taxa = taxa)

  info <- lapply(aux_dest, ler_aux)
  s[, `:=`(aux_http = data.table::fifelse(file.exists(aux_dest), 200L, r_aux$http),
           n_hashes = vapply(info, `[[`, 1L, "n_hashes"),
           hash_st  = vapply(info, `[[`, "", "hash_st"))]
  ok <- which(vapply(info, function(x) !is.null(x[["hash"]]), TRUE))

  arquivos <- rbindlist(lapply(c("log", "bu"), function(tp) {
    s[ok, .(i = ok, tp = tp,
            url = url_arquivo(pleito, uf, mun, zona, secao,
                              vapply(info[ok], `[[`, "", "hash"),
                              vapply(info[ok], `[[`, "", tp)),
            destino = caminho_cache(raiz, pleito, uf, mun, zona, secao, tp))]
  }))
  r_arq <- baixar_lote(arquivos$url, arquivos$destino, taxa = taxa)
  arquivos[, ok_arq := file.exists(destino) & file.size(destino) > 0]
  s[, `:=`(log_ok = FALSE, bu_ok = FALSE)]
  s[arquivos[tp == "log" & ok_arq, i], log_ok := TRUE]
  s[arquivos[tp == "bu" & ok_arq, i], bu_ok := TRUE]
  status[[b]] <- s

  feitos <- sum(lengths(blocos[seq_len(b)]))
  dt <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  cli::cli_alert_info(sprintf("bloco %d/%d | %d seções | %.1f min | estimativa restante %.0f min",
    b, length(blocos), feitos, dt, dt / feitos * (nrow(secoes) - feitos)))
}

status <- rbindlist(c(status, list(agregadas[, `:=`(aux_http = NA_integer_, n_hashes = NA_integer_, hash_st = NA_character_, log_ok = FALSE, bu_ok = FALSE)])), use.names = TRUE)
arrow::write_parquet(status, sprintf("dados/indice/status_%s%s.parquet", pleito,
                                     if (is.null(amostra)) "" else "_amostra"))
print(status[, .(secoes = .N, aux_404 = sum(aux_http == 404L, na.rm = TRUE),
                 sem_log = sum(!log_ok), sem_bu = sum(!bu_ok),
                 hash_nao_totalizado = sum(hash_st != "Totalizado", na.rm = TRUE),
                 mais_de_um_hash = sum(n_hashes > 1L, na.rm = TRUE))])
