# Relatório da validação log × boletim de urna.
# Uso: Rscript scripts/04_validar.R [--amostra]
# Requer: dados/processados[/amostra]/secoes.parquet (scripts/03_processar.R)
# Saída: resultados/validacao[_amostra].md

pkgload::load_all(quiet = TRUE)
library(data.table)

amostra <- "--amostra" %in% commandArgs(trailingOnly = TRUE)
entrada <- if (amostra) "dados/processados/amostra/secoes.parquet" else "dados/processados/secoes.parquet"
saida   <- sprintf("resultados/validacao%s.md", if (amostra) "_amostra" else "")
dir.create("resultados", showWarnings = FALSE)

s <- as.data.table(arrow::read_parquet(entrada))
tab <- dcast(s[, .N, by = .(uf, categoria)], uf ~ categoria, value.var = "N", fill = 0L)
tot <- s[, .N, by = categoria][order(-N)][, pct := sprintf("%.2f%%", 100 * N / sum(N))]
link <- function(x) sprintf("[%s %s/%s/%s](%s)", x$uf, x$mun, x$zona, x$secao,
                            url_aux("3221", x$uf, x$mun, x$zona, x$secao))
md_tab <- function(d) {
  d <- as.data.frame(d)
  c(paste("|", paste(names(d), collapse = " | "), "|"),
    paste("|", paste(rep("---", ncol(d)), collapse = " | "), "|"),
    apply(d, 1, function(r) paste("|", paste(r, collapse = " | "), "|")))
}
ne <- s[categoria == "nao_explicada"]
ok_cont <- s[categoria %in% c("ok", "urna_substituida")]

linhas <- c(
  sprintf("# Validação log × boletim de urna%s", if (amostra) " (amostra de validação)" else ""),
  "",
  sprintf("Gerado em %s (horário de Brasília). Seções: %d.",
          format(Sys.time(), "%Y-%m-%d %H:%M", tz = "America/Sao_Paulo"), nrow(s)),
  "",
  "Para cada seção, os votos reconstruídos do log da urna são comparados com o",
  "boletim de urna (BU) assinado: total de comparecimento e forma de habilitação",
  "(biometria, ano de nascimento, sem biometria cadastrada).",
  "",
  "## Categorias", "", md_tab(tot), "",
  sprintf("Votos conferidos nas seções que batem: %s (log) = %s (BU).",
          format(sum(ok_cont$votos_log), big.mark = "."),
          format(sum(ok_cont$comparecimento_bu), big.mark = ".")),
  "", "## Por UF", "", md_tab(tab), "",
  "## Seções não explicadas", "",
  if (nrow(ne)) md_tab(ne[, .(secao = link(.SD), votos_log, comparecimento_bu, dif, erro_log)]) else "Nenhuma.",
  ""
)
writeLines(linhas, saida, useBytes = TRUE)
cli::cli_alert_success("{saida}")
print(tot)
