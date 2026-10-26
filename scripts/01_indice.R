# Baixa o índice de seções de todas as UFs (e do exterior, "zz") de um pleito.
# Uso: Rscript scripts/01_indice.R [pleito]   (padrão: 3221, o 2º turno)
# Saída: dados/indice/secoes_<pleito>.parquet

pkgload::load_all(quiet = TRUE)

UFS <- c("ac", "al", "am", "ap", "ba", "ce", "df", "es", "go", "ma", "mg", "ms", "mt",
         "pa", "pb", "pe", "pi", "pr", "rj", "rn", "ro", "rr", "rs", "sc", "se", "sp",
         "to", "zz")

args <- commandArgs(trailingOnly = TRUE)
pleito <- if (length(args) >= 1) args[1] else "3221"

dir.create("dados/indice", showWarnings = FALSE, recursive = TRUE)
destinos <- sprintf("dados/indice/cs/%s-p%s-cs.json", UFS, pleito)
r <- baixar_lote(url_indice(pleito, UFS), destinos)
if (any(r$http != 200L & r$tentativas > 0L, na.rm = TRUE)) stop("falha ao baixar índice: ",
  paste(UFS[which(r$http != 200L)], collapse = ", "))

secoes <- data.table::rbindlist(lapply(destinos, ler_indice_secoes))
arrow::write_parquet(secoes, sprintf("dados/indice/secoes_%s.parquet", pleito))
cli::cli_alert_success("{nrow(secoes)} seções em {length(unique(secoes$uf))} UFs")
print(secoes[, .N, by = uf][order(-N)])
