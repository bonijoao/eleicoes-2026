# Baixa do TSE os arquivos de quatro seções reais do 2º turno usadas nos testes.
# Uso: Rscript scripts/00_fixtures.R

pkgload::load_all(quiet = TRUE)

secoes <- data.frame(
  uf    = c("ac",    "sp",    "sp",    "sp"),
  mun   = c("01074", "64777", "64157", "65897"),
  zona  = c("0004",  "0394",  "0401",  "0062"),
  secao = c("0001",  "0307",  "0306",  "0046"),
  motivo = c("simples, fuso UTC-5",
             "log aninhado com .jez interno de 25/10",
             "log aninhado com .jez interno de 28/09",
             "aux.json responde 404")
)
destino <- "tests/testthat/fixtures"
dir.create(destino, showWarnings = FALSE, recursive = TRUE)

for (i in seq_len(nrow(secoes))) {
  s <- secoes[i, ]
  id <- sprintf("%s-%s-%s-%s", s$uf, s$mun, s$zona, s$secao)
  r <- curl::curl_fetch_memory(url_aux("3221", s$uf, s$mun, s$zona, s$secao))
  if (r$status_code != 200) {
    writeLines(sprintf("HTTP %d em %s (horário de Brasília)", r$status_code,
                       format(Sys.time(), tz = "America/Sao_Paulo")),
               file.path(destino, paste0(id, "-404.txt")))
    next
  }
  writeBin(r$content, file.path(destino, paste0(id, "-aux.json")))
  aux <- jsonlite::fromJSON(rawToChar(r$content))
  arq <- aux$hashes$arq[[1]]
  for (tp in c("log", "bu")) {
    nome <- arq$nm[arq$tp == tp]
    curl::curl_download(url_arquivo("3221", s$uf, s$mun, s$zona, s$secao, aux$hashes$hash[1], nome),
                        file.path(destino, sprintf("%s-%s.%s", id, tp, EXT_CACHE[[tp]])), quiet = TRUE)
  }
  message(id, ": ", s$motivo)
}
