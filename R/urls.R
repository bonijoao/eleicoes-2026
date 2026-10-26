# Endereços públicos dos arquivos de urna no servidor de resultados do TSE.
# Todos os argumentos são character; mun, zona e secao chegam com zeros à
# esquerda (5, 4 e 4 dígitos) e uf em minúsculas. Funções vetorizadas.

BASE_TSE <- "https://resultados.tse.jus.br/oficial/ele2026/arquivo-urna"

pleito6 <- function(pleito) sprintf("%06d", as.integer(pleito))

url_indice <- function(pleito, uf) {
  sprintf("%s/%s/config/%s/%s-p%s-cs.json", BASE_TSE, pleito, uf, uf, pleito6(pleito))
}

dir_secao <- function(pleito, uf, mun, zona, secao) {
  sprintf("%s/%s/dados/%s/%s/%s/%s", BASE_TSE, pleito, uf, mun, zona, secao)
}

url_aux <- function(pleito, uf, mun, zona, secao) {
  sprintf("%s/p%s-%s-m%s-z%s-s%s-aux.json",
          dir_secao(pleito, uf, mun, zona, secao), pleito6(pleito), uf, mun, zona, secao)
}

url_arquivo <- function(pleito, uf, mun, zona, secao, hash, nome) {
  sprintf("%s/%s/%s", dir_secao(pleito, uf, mun, zona, secao), hash, nome)
}

EXT_CACHE <- c(aux = "json", log = "jez", bu = "dat")

caminho_cache <- function(raiz, pleito, uf, mun, zona, secao, tipo) {
  sprintf("%s/%s/%s/%s-%s-%s-%s.%s", raiz, pleito, uf, mun, zona, secao, tipo,
          unname(EXT_CACHE[tipo]))
}
