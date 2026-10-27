# Investigação 2 do pré-registro: "voto espírita".
# Uso: Rscript scripts/07_voto_espirita.R
# Requer: dados/processados/{secoes,validacao_1t,resumo_votos}.parquet e
#         resultados/rajada_delta.json (scripts/05_resumo_votos.R)
# Saída: resultados/voto_espirita.md, resultados/voto_espirita.json,
#        resultados/voto_espirita_sinais.csv

pkgload::load_all(quiet = TRUE)
library(data.table)

secoes <- as.data.table(arrow::read_parquet("dados/processados/secoes.parquet"))
v1     <- as.data.table(arrow::read_parquet("dados/processados/validacao_1t.parquet"))
resumo <- as.data.table(arrow::read_parquet("dados/processados/resumo_votos.parquet"))
delta  <- jsonlite::read_json("resultados/rajada_delta.json")$delta_s

p_mun <- secoes[!is.na(pres_13) & !is.na(pres_22),
                .(p13 = sum(pres_13) / sum(pres_13 + pres_22), p22 = sum(pres_22) / sum(pres_13 + pres_22)),
                by = .(uf, mun)]

cols <- c("votos", "manual", "sem_bio", "apos_1600", "manual_apos_1600", "rajada")
s <- secoes[categoria %in% c("ok", "urna_substituida"),
            .(uf, mun, zona, secao, pres_13, pres_22,
              por_horario = uf != "zz" & !((confianca_offset < 0.8) %in% TRUE | fuso_suspeito %in% TRUE |
                                             abertura_destoa %in% TRUE))]
s <- merge(s, resumo[turno == 2L, c(CHAVE_SECAO, cols), with = FALSE], by = CHAVE_SECAO, all.x = TRUE)
s <- merge(s, setnames(resumo[turno == 1L, c(CHAVE_SECAO, cols), with = FALSE], cols, paste0(cols, "_1t")),
           by = CHAVE_SECAO, all.x = TRUE)
s <- merge(s, v1[, .(uf, mun, zona, secao, categoria_1t)], by = CHAVE_SECAO, all.x = TRUE)
s[, controle := categoria_1t %in% "ok" & votos_1t > 0]
s[por_horario == FALSE, `:=`(manual_apos_1600 = NA, manual_apos_1600_1t = NA)]
s[, mun_id := paste(uf, mun)]

# Métrica 2: excesso em relação ao 1º turno, encolhido para o município.
excesso <- function(s, y2, y1) {
  ct <- s[controle == TRUE]
  m <- ct[, .(m_mun = sum(get(y1)) / sum(votos_1t)), by = mun_id]
  ct <- merge(ct, m, by = "mun_id")
  k <- ct[, .(kappa = kappa_mom(get(y1), votos_1t, m_mun)), by = uf]
  ct <- merge(ct, k, by = "uf")
  ct[, p := taxa_encolhida(get(y1), votos_1t, m_mun, kappa)]
  phi <- phi_pearson(ct[[y2]], ct$votos, ct$p)
  ct[, z := escore_z(get(y2), votos, p, phi)]
  list(z = ct[, .(uf, mun, zona, secao, z, e0 = votos * p <= 0 & get(y2) > 0)], kappa = k, phi = phi)
}
ex  <- excesso(s, "manual", "manual_1t")
exs <- excesso(s, "sem_bio", "sem_bio_1t")
s <- merge(s, ex$z, by = CHAVE_SECAO, all.x = TRUE)
s <- merge(s, exs$z[, .(uf, mun, zona, secao, z_sem = z, e0_sem = e0)], by = CHAVE_SECAO, all.x = TRUE)
s2 <- cbind(s, s[, sinais(z, manual, manual_apos_1600, votos, apos_1600, rajada, z_sem)])

# Placebo: o 1º turno com as mesmas regras, esperado pelo município sem a própria seção.
pl <- s[controle == TRUE]
pl[, p_loo := taxa_deixa_um_fora(manual_1t, votos_1t, mun_id)]
pl[, p_loo_sem := taxa_deixa_um_fora(sem_bio_1t, votos_1t, mun_id)]
phi_pl     <- phi_pearson(pl$manual_1t, pl$votos_1t, pl$p_loo)
phi_pl_sem <- phi_pearson(pl$sem_bio_1t, pl$votos_1t, pl$p_loo_sem)
pl[, `:=`(z = escore_z(manual_1t, votos_1t, p_loo, phi_pl), z_sem = escore_z(sem_bio_1t, votos_1t, p_loo_sem, phi_pl_sem))]
pl <- cbind(pl[, .(uf, mun, zona, secao, z, z_sem)],
            pl[, sinais(z, manual_1t, manual_apos_1600_1t, votos_1t, apos_1600_1t, rajada_1t, z_sem)])

# Resumos.
dec <- function(x, d) formatC(x, format = "f", digits = d, decimal.mark = ",")
conta <- function(x) x[, .(s1 = sum(s1), s1b = sum(s1b), s2 = sum(s2), s3 = sum(s3),
                           dois_ou_mais = sum(n_sinais >= 2L))]
q <- function(x) as.list(setNames(stats::quantile(x, c(0.5, 0.9, 0.99, 0.999), na.rm = TRUE, names = FALSE),
                                  c("p50", "p90", "p99", "p999")))
taxa_manual <- list(turno2 = q(s$manual / s$votos), turno1 = q(s[controle == TRUE, manual_1t / votos_1t]))
c2_todas <- conta(s2)
c2_ctrl  <- conta(s2[controle == TRUE])
c_pl     <- conta(pl)
fav <- merge(s2[n_sinais >= 2L], p_mun, by = c("uf", "mun"))[
  , .(secoes = .N, saldo_22_13_observado = sum(pres_22 - pres_13),
      saldo_22_13_esperado = sum((pres_13 + pres_22) * (p22 - p13)))]
combos <- s2[n_sinais >= 2L, .N, by = .(sinais = trimws(paste0(fifelse(s1, "1 ", ""), fifelse(s1b, "1b ", ""),
                                                          fifelse(s2, "2 ", ""), fifelse(s3, "3", ""))))][order(-N)]

# Diagnóstico do sinal 3 (scripts/07b_rajada_diagnostico.R; DESVIOS.md, 2026-10-27).
secao_diag <- if (file.exists("resultados/rajada_diagnostico.json")) {
  dg <- jsonlite::read_json("resultados/rajada_diagnostico.json", simplifyVector = TRUE)
  nac <- as.data.table(dg$nacional)[order(turno)]
  hr <- as.data.table(dg$rajadas_por_hora)
  hr2 <- hr[turno == 2L][order(hora)]
  c("### O sinal 3 não separa nada no 2º turno", "",
    "O limiar δ saiu do 1º turno, como pré-registrado. A cédula do 2º turno é bem mais curta,",
    "então cada eleitor leva menos tempo na urna e intervalos abaixo de δ viram rotina:", "",
    md_tab(data.table(turno = c("1º turno", "2º turno"),
                      `intervalo mediano (s)` = fmt_int(nac$mediana_s),
                      `intervalos abaixo de δ` = paste0(dec(100 * nac$fracao_abaixo, 2), "%"))), "",
    "Por isso o sinal 3 aparece em dezenas de milhares de seções no 2º turno e quase nenhuma no",
    "placebo, e a comparação com o placebo não vale para ele. A hora em que as rajadas do 2º",
    "turno começam (Brasília) mostra fila de manhã, não votos no fim do dia:", "",
    md_tab(data.table(hora = sprintf("%02dh", hr2$hora), rajadas = fmt_int(hr2$rajadas))), "",
    "As contas pré-registradas não mudam. Por UF: `resultados/rajada_diagnostico_uf.csv`.")
}

tab_sinais <- md_tab(data.table(
  sinal = c("1: excesso de habilitação manual (z > 4)", "1b: excesso de sem biometria (z > 4)",
            "2: manual concentrada no fim do dia", "3: rajada de 10 votos ou mais", "dois ou mais sinais"),
  `2º turno, todas` = fmt_int(unlist(c2_todas)),
  `2º turno, com controle` = fmt_int(unlist(c2_ctrl)),
  `1º turno (placebo)` = fmt_int(unlist(c_pl))))

linhas <- c(
  "# Investigação 2: \"voto espírita\"", "",
  sprintf("Gerado em %s (horário de Brasília). Método: `PREREGISTRO.md`, seção 4, e `DESVIOS.md`.",
          format(Sys.time(), "%Y-%m-%d %H:%M", tz = "America/Sao_Paulo")), "",
  "**Alegação:** mesários teriam votado no lugar de eleitores ausentes. Isso deixaria",
  "excesso de habilitação manual ou sem biometria, concentrado no fim do dia e em votos",
  "seguidos e rápidos.", "",
  "## Seções", "",
  sprintf("Analisadas: %s (categorias `ok` e `urna_substituida`). Com controle pelo 1º turno: %s.",
          fmt_int(nrow(s)), fmt_int(s[controle == TRUE, .N])),
  sprintf("Com horário confiável (métrica 3): %s.", fmt_int(s[por_horario == TRUE, .N])), "",
  "## Métrica 1: taxa de habilitação manual por seção", "",
  md_tab(data.table(turno = c("2º turno", "1º turno"),
                    mediana = dec(c(taxa_manual$turno2$p50, taxa_manual$turno1$p50), 3),
                    p90 = dec(c(taxa_manual$turno2$p90, taxa_manual$turno1$p90), 3),
                    p99 = dec(c(taxa_manual$turno2$p99, taxa_manual$turno1$p99), 3),
                    `p99,9` = dec(c(taxa_manual$turno2$p999, taxa_manual$turno1$p999), 3))), "",
  "## Métrica 2: escore de excesso", "",
  sprintf("Sobredispersão φ = %s (manual) e %s (sem biometria); placebo: %s e %s.",
          dec(ex$phi, 2), dec(exs$phi, 2), dec(phi_pl, 2), dec(phi_pl_sem, 2)),
  sprintf("Seções com esperado zero e habilitação manual no 2º turno (sem escore): %d.",
          s[e0 %in% TRUE, .N]), "",
  md_tab(data.table(escore = c("z, 2º turno", "z, placebo"),
                    p50 = dec(c(q(s$z)$p50, q(pl$z)$p50), 2),
                    p99 = dec(c(q(s$z)$p99, q(pl$z)$p99), 2),
                    `p99,9` = dec(c(q(s$z)$p999, q(pl$z)$p999), 2),
                    `z > 4` = fmt_int(c(sum(s$z > 4, na.rm = TRUE), sum(pl$z > 4, na.rm = TRUE))))), "",
  "## Sinais", "",
  sprintf("Rajada: δ = %d s, fixado pelo 1º turno antes da análise do 2º (`resultados/rajada_delta.json`).", delta), "",
  tab_sinais, "",
  "Combinações nas seções do 2º turno com dois ou mais sinais:", "",
  if (nrow(combos)) md_tab(combos) else "Nenhuma.", "",
  secao_diag, "",
  "## A favor de quem?", "",
  "Nas seções do 2º turno com dois ou mais sinais, o saldo Flávio − Lula observado e o",
  "esperado pelas proporções do município:", "",
  md_tab(fav[, lapply(.SD, fmt_int)]), "",
  "## Como ler", "",
  "- Indício compatível com a alegação seria um número de seções com dois ou mais sinais",
  "  muito acima do placebo do 1º turno, concentrado a favor de um candidato.",
  "- Uma seção isolada fora da curva não prova nada: com ~500 mil seções, alguns extremos",
  "  são esperados por acaso e por problemas operacionais.",
  "- As seções com dois ou mais sinais são examinadas uma a uma em `resultados/voto_espirita_casos.md`.",
  "- Lista completa das seções com algum sinal: `resultados/voto_espirita_sinais.csv`.", ""
)
writeLines(linhas, "resultados/voto_espirita.md", useBytes = TRUE)

jsonlite::write_json(list(
  delta_s = delta, phi = ex$phi, phi_sem = exs$phi, phi_placebo = phi_pl, phi_placebo_sem = phi_pl_sem,
  kappa_uf = ex$kappa, kappa_uf_sem = exs$kappa, taxa_manual = taxa_manual,
  z = list(turno2 = q(s$z), placebo = q(pl$z)),
  secoes = list(analisadas = nrow(s), com_controle = s[controle == TRUE, .N], por_horario = s[por_horario == TRUE, .N]),
  sinais = list(turno2_todas = c2_todas, turno2_com_controle = c2_ctrl, placebo = c_pl),
  e0_com_manual = s[e0 %in% TRUE, .N], favorecimento = fav, combinacoes = combos),
  "resultados/voto_espirita.json", auto_unbox = TRUE, pretty = TRUE, digits = NA)

lista <- rbind(s2[n_sinais > 0L, .(turno = 2L, uf, mun, zona, secao, z, z_sem, s1, s1b, s2, s3, n_sinais)],
               pl[n_sinais > 0L, .(turno = 1L, uf, mun, zona, secao, z, z_sem, s1, s1b, s2, s3, n_sinais)])
lista[, link := url_aux("3221", uf, mun, zona, secao)]
fwrite(lista[order(turno, -n_sinais, uf, mun, zona, secao)], "resultados/voto_espirita_sinais.csv")
cli::cli_alert_success("resultados/voto_espirita.md")
print(rbind(cbind(grupo = "2T todas", c2_todas), cbind(grupo = "2T controle", c2_ctrl), cbind(grupo = "placebo", c_pl)))
