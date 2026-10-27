# Investigação 1 do pré-registro: a prorrogação até as 19h.
# Uso: Rscript scripts/06_prorrogacao.R
# Requer: dados/processados/{secoes,validacao_1t,resumo_votos}.parquet e
#         dados/indice/bweb_1t.parquet
# Saída: resultados/prorrogacao.md, resultados/prorrogacao.json,
#        resultados/prorrogacao_uf.csv

pkgload::load_all(quiet = TRUE)
library(data.table)

secoes <- as.data.table(arrow::read_parquet("dados/processados/secoes.parquet"))
v1     <- as.data.table(arrow::read_parquet("dados/processados/validacao_1t.parquet"))
resumo <- as.data.table(arrow::read_parquet("dados/processados/resumo_votos.parquet"))
bweb1  <- as.data.table(arrow::read_parquet("dados/indice/bweb_1t.parquet"))

# Proporções dos candidatos nos votos válidos do município (todas as seções com urna).
p <- secoes[!is.na(pres_13) & !is.na(pres_22),
            .(p13 = sum(pres_13) / sum(pres_13 + pres_22), p22 = sum(pres_22) / sum(pres_13 + pres_22)),
            by = .(uf, mun)]

base <- secoes[categoria %in% c("ok", "urna_substituida") & uf != "zz",
               .(uf, mun, zona, secao, aptos, encerramento_log_bsb,
                 marca_fuso = (confianca_offset < 0.8) %in% TRUE | fuso_suspeito %in% TRUE | abertura_destoa %in% TRUE)]
base <- merge(base, resumo[turno == 2L, .(uf, mun, zona, secao, votos_2t = votos,
                                          apos_1700_2t = apos_1700, apos_1703_2t = apos_1703)],
              by = CHAVE_SECAO, all.x = TRUE)
base <- merge(base, resumo[turno == 1L, .(uf, mun, zona, secao, apos_1700_1t = apos_1700, apos_1703_1t = apos_1703)],
              by = CHAVE_SECAO, all.x = TRUE)
base <- merge(base, v1[, .(uf, mun, zona, secao, categoria_1t)], by = CHAVE_SECAO, all.x = TRUE)
base <- merge(base, bweb1[, .(uf, mun, zona, secao, aptos_1t = aptos)], by = CHAVE_SECAO, all.x = TRUE)
base[, grupo := grupo_decisao(encerramento_log_bsb)]
base[, controle := categoria_1t %in% "ok" & !is.na(apos_1700_1t) & aptos_1t > 0]

analisar <- function(s) {
  b <- s[grupo == "B" & controle][, efeito := efeito_prorrogacao(apos_1700_2t, aptos, apos_1700_1t, aptos_1t)]
  a <- taxa_referencia(b[, .(uf, mun, aptos, efeito)], s[grupo == "A", .(uf, mun, zona, secao, aptos)])
  r95 <- b[, .(r95 = stats::quantile(efeito, 0.95, names = FALSE)), by = uf]
  mun_b <- b[, .(r_m = stats::median(efeito), n = .N), by = .(uf, mun)][n >= 5L]
  teto <- teto_voto_perdido(a, p, r95)
  teto_uf <- rbindlist(lapply(split(a, by = "uf"), function(x) {
    t <- teto_voto_perdido(x, p, r95)
    data.table(uf = x$uf[1], secoes_A = nrow(x), bruto = t$bruto, liquido = t$liquido,
               pior_caso = t$pior_caso, sem_taxa = t$sem_taxa)
  }))
  list(
    n = list(secoes = nrow(s), A = s[grupo == "A", .N], B = s[grupo == "B", .N],
             sem_encerramento = s[is.na(grupo), .N], B_com_controle = nrow(b)),
    metrica1 = list(
      turno2 = list(votos = sum(s$votos_2t, na.rm = TRUE), apos_1700 = sum(s$apos_1700_2t, na.rm = TRUE),
                    apos_1703 = sum(s$apos_1703_2t, na.rm = TRUE)),
      turno1 = list(secoes = s[!is.na(apos_1700_1t), .N], apos_1700 = sum(s$apos_1700_1t, na.rm = TRUE),
                    apos_1703 = sum(s$apos_1703_1t, na.rm = TRUE))),
    metrica2 = c(list(media = mean(b$efeito)),
                 as.list(setNames(stats::quantile(b$efeito, c(0.05, 0.25, 0.5, 0.75, 0.95), names = FALSE),
                                  c("p05", "p25", "p50", "p75", "p95")))),
    fonte_r = as.list(table(factor(a$fonte_r, c("municipio", "uf_quintil", "sem_taxa")))),
    n_mun_r_negativo = mun_b[r_m < 0, .N], n_mun_com_r = nrow(mun_b),
    teto = teto, teto_uf = teto_uf,
    metrica1_uf = s[, .(secoes = .N, apos_1700_2t = sum(apos_1700_2t, na.rm = TRUE),
                        apos_1703_2t = sum(apos_1703_2t, na.rm = TRUE),
                        apos_1700_1t = sum(apos_1700_1t, na.rm = TRUE),
                        apos_1703_1t = sum(apos_1703_1t, na.rm = TRUE)), by = uf]
  )
}

princ <- analisar(base[marca_fuso == FALSE])
parte <- analisar(base[marca_fuso == TRUE])

dec <- function(x, d) formatC(x, format = "f", digits = d, decimal.mark = ",")
pct <- function(x) paste0(dec(100 * x / MARGEM_OFICIAL, 1), "%")
num <- function(x) fmt_int(round(x))
tab_teto <- function(r) md_tab(data.table(
  camada = c("bruto", "líquido para Flávio", "pior caso"),
  votos = num(c(r$teto$bruto, r$teto$liquido, r$teto$pior_caso)),
  `% da margem` = c("—", pct(r$teto$liquido), pct(r$teto$pior_caso)),
  premissas = c("eleitores aptos das seções A × mediana do efeito nas seções B parecidas",
                "bruto × (proporção de Flávio − proporção de Lula) no município",
                "eleitores aptos das seções A × percentil 95 do efeito na UF; todos votariam em Flávio")))

linhas <- c(
  "# Investigação 1: a prorrogação até as 19h", "",
  sprintf("Gerado em %s (horário de Brasília). Método: `PREREGISTRO.md`, seção 3, e `DESVIOS.md`.",
          format(Sys.time(), "%Y-%m-%d %H:%M", tz = "America/Sao_Paulo")), "",
  "**Pergunta:** quantos votos, no máximo, poderiam ter sido perdidos nas seções que já",
  "tinham encerrado quando a decisão saiu (17h03 de Brasília), e esse número chega perto",
  sprintf("da margem de %s votos?", fmt_int(MARGEM_OFICIAL)), "",
  if (princ$teto$pior_caso > 0.5 * MARGEM_OFICIAL)
    c(sprintf("**O pior caso (%s votos) passa de 50%% da margem.**", num(princ$teto$pior_caso)), ""),
  "## Seções", "",
  md_tab(data.table(
    grupo = c("analisadas", "A: encerrada até 17h03", "B: encerrada depois de 17h03", "sem encerramento no log",
              "B com controle pelo 1º turno", "analisadas à parte (fuso incerto)"),
    secoes = fmt_int(c(princ$n$secoes, princ$n$A, princ$n$B, princ$n$sem_encerramento,
                       princ$n$B_com_controle, parte$n$secoes)))), "",
  "Ficam fora o exterior e as seções fora das categorias `ok` e `urna_substituida`.", "",
  "## Métrica 1: votos depois das 17h00 e das 17h03", "",
  md_tab(data.table(
    turno = c("2º turno (25/10)", "1º turno (04/10)"),
    `depois das 17h00` = fmt_int(c(princ$metrica1$turno2$apos_1700, princ$metrica1$turno1$apos_1700)),
    `depois das 17h03` = fmt_int(c(princ$metrica1$turno2$apos_1703, princ$metrica1$turno1$apos_1703)))), "",
  sprintf("No 2º turno, as seções analisadas somam %s votos. Por UF: `resultados/prorrogacao_uf.csv`.",
          fmt_int(princ$metrica1$turno2$votos)), "",
  "## Métrica 2: efeito da prorrogação nas seções B", "",
  "Taxa de votos depois das 17h00 por eleitor apto no 2º turno, menos a mesma taxa no 1º",
  "turno, quando não houve prorrogação.", "",
  md_tab(data.table(estatistica = c("média", "p5", "p25", "mediana", "p75", "p95"),
                    efeito = dec(unlist(princ$metrica2), 4))), "",
  "## Métrica 3: teto do voto perdido nas seções A", "",
  tab_teto(princ), "",
  sprintf("Taxa de referência das seções A: %s pelo município, %s por UF e quintil de aptos, %s sem taxa.",
          fmt_int(princ$fonte_r$municipio), fmt_int(princ$fonte_r$uf_quintil), fmt_int(princ$fonte_r$sem_taxa)),
  sprintf("Municípios com mediana do efeito negativa: %s de %s.", fmt_int(princ$n_mun_r_negativo), fmt_int(princ$n_mun_com_r)), "",
  if (princ$teto$bruto < 0)
    c("O bruto é negativo: nas seções B, a taxa de votos depois das 17h00 no 2º turno ficou, em geral,",
      "abaixo da do 1º turno. Com o bruto negativo, o líquido não mede votos perdidos; o sinal dele",
      "só reflete se o município pende para Lula ou para Flávio. O teto que responde à pergunta é o",
      "pior caso.", ""),
  "## Seções analisadas à parte (fuso incerto)", "",
  sprintf("%s seções (A: %s; B: %s). Mesmas contas:", fmt_int(parte$n$secoes), fmt_int(parte$n$A), fmt_int(parte$n$B)), "",
  tab_teto(parte), ""
)
writeLines(linhas, "resultados/prorrogacao.md", useBytes = TRUE)

sem_uf <- function(r) r[setdiff(names(r), c("teto_uf", "metrica1_uf"))]
jsonlite::write_json(list(margem = MARGEM_OFICIAL, decisao = "2026-10-25 17:03:00",
                          principal = sem_uf(princ), a_parte = sem_uf(parte)),
                     "resultados/prorrogacao.json", auto_unbox = TRUE, pretty = TRUE, digits = NA)
fwrite(merge(princ$metrica1_uf, princ$teto_uf, by = "uf", all.x = TRUE), "resultados/prorrogacao_uf.csv")
cli::cli_alert_success("resultados/prorrogacao.md")
