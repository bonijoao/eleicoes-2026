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
ci <- s[categoria == "coleta_incompleta"]
# Total de seções instaladas no 2º turno segundo o TSE; a diferença para as
# seções com urna do índice são as que o TSE marca como "Sem arquivo".
SECOES_INSTALADAS_TSE <- 499207L
n_urna    <- s[categoria != "agregada", .N]
n_sem_arq <- s[categoria != "agregada" & hash_st %in% "Sem arquivo", .N]

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
  "",
  "## Seções com coleta incompleta", "",
  "Seções com urna (não agregadas) em que falta o log, o BU ou os dois. O estado",
  "vem do aux.json publicado pelo TSE para a seção.", "",
  if (nrow(ci)) md_tab(ci[, .N, by = .(local = fifelse(uf == "zz", "exterior", "Brasil"),
                                      estado_tse = hash_st,
                                      log = fifelse(is.na(votos_log), "não", "sim"),
                                      bu = fifelse(is.na(comparecimento_bu), "não", "sim"))
                          ][order(local, estado_tse, log, bu)]) else "Nenhuma.",
  "",
  if (!amostra) c(
    sprintf("Seções com urna no índice: %s. Sem as %d em estado \"Sem arquivo\" no TSE: %s.",
            format(n_urna, big.mark = "."), n_sem_arq, format(n_urna - n_sem_arq, big.mark = ".")),
    sprintf("O TSE divulga %s seções instaladas no 2º turno.", format(SECOES_INSTALADAS_TSE, big.mark = ".")),
    ""),
  "## Marcas nas seções analisadas (ok e urna substituída)", "",
  md_tab(ok_cont[, .(
    `hash não totalizado` = sum(!is.na(hash_st) & hash_st != "Totalizado"),
    `fuso suspeito no município` = sum(fuso_suspeito %in% TRUE),
    `abertura destoa do município` = sum(abertura_destoa %in% TRUE),
    `habilitados sem voto` = sum(habilitados_sem_voto, na.rm = TRUE))]),
  ""
)

# Validação do 1º turno (controle das investigações), se o BU consolidado existir.
if (file.exists("dados/indice/bweb_1t.parquet")) {
  b1 <- as.data.table(arrow::read_parquet("dados/indice/bweb_1t.parquet"))
  v1 <- merge(ok_cont[, .(uf, mun, zona, secao, votos_log_1t, log_tem_1t)], b1, by = c("uf", "mun", "zona", "secao"), all.x = TRUE)
  # urna_diferente_no_1t: o log não tem nenhum registro de 04/10 (a urna do 2º
  # turno não foi a do 1º); nessas seções não há controle pelo 1º turno.
  v1[, categoria_1t := fcase(is.na(comparecimento), "sem_bu_1t",
                             log_tem_1t %in% FALSE, "urna_diferente_no_1t",
                             votos_log_1t == comparecimento, "ok",
                             default = "diferente")]
  linhas <- c(linhas, "## 1º turno: log × BU consolidado do TSE", "",
              "O 1º turno está no mesmo log da urna e serve de controle nas duas investigações.", "",
              md_tab(v1[, .N, by = categoria_1t][order(-N)]), "")
  arrow::write_parquet(v1[, .(uf, mun, zona, secao, categoria_1t)],
                       sub("secoes.parquet", "validacao_1t.parquet", entrada, fixed = TRUE))
}
writeLines(linhas, saida, useBytes = TRUE)
cli::cli_alert_success("{saida}")
print(tot)
