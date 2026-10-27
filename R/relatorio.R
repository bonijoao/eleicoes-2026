# Peças comuns dos relatórios em resultados/: tabela Markdown, link para os
# arquivos da seção no TSE e inteiros com milhar separado por ponto.

md_tab <- function(d) {
  d <- as.data.frame(d)
  c(paste("|", paste(names(d), collapse = " | "), "|"),
    paste("|", paste(rep("---", ncol(d)), collapse = " | "), "|"),
    apply(d, 1, function(r) paste("|", paste(r, collapse = " | "), "|")))
}

link_secao <- function(uf, mun, zona, secao, pleito = "3221") {
  sprintf("[%s %s/%s/%s](%s)", uf, mun, zona, secao, url_aux(pleito, uf, mun, zona, secao))
}

fmt_int <- function(x) formatC(x, format = "d", big.mark = ".", decimal.mark = ",")
