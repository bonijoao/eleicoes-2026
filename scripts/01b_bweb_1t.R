# Baixa o boletim de urna consolidado do 1º turno (portal de dados abertos do
# TSE) e resume o comparecimento por seção, para validar o 1º turno do log, que
# é o controle das duas investigações.
# Uso: Rscript scripts/01b_bweb_1t.R
# Saída: dados/indice/bweb_1t.parquet

pkgload::load_all(quiet = TRUE)

UFS <- c("AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", "MA", "MG", "MS", "MT",
         "PA", "PB", "PE", "PI", "PR", "RJ", "RN", "RO", "RR", "RS", "SC", "SE", "SP",
         "TO", "ZZ")
base <- "https://cdn.tse.jus.br/estatistica/sead/eleicoes/eleicoes2026/buweb"
dest <- sprintf("dados/brutos/bweb_1t/bweb_1t_%s_051020261403.zip", UFS)
r <- baixar_lote(sprintf("%s/%s", base, basename(dest)), dest, conc = 4L)
print(r[, .(arquivo = basename(destino), http, mb = round(bytes / 1e6))])

x <- data.table::rbindlist(lapply(dest[file.exists(dest)], ler_bweb))
arrow::write_parquet(x, "dados/indice/bweb_1t.parquet")
cli::cli_alert_success("{nrow(x)} seções com BU do 1º turno")
