# Índice de seções publicado pelo TSE (arquivo <uf>-p<pleito>-cs.json):
# abr -> mu (municípios) -> zon (zonas) -> sec (seções).
# Seção agregada traz "nsp" (a seção principal onde seus eleitores votam) e
# não tem urna nem arquivos próprios; a principal lista as agregadas em "nsa".

ler_indice_secoes <- function(json_path_ou_url) {
  cs <- jsonlite::fromJSON(json_path_ou_url, simplifyVector = FALSE)
  data.table::rbindlist(lapply(cs$abr, function(a) {
    data.table::rbindlist(lapply(a$mu, function(m) {
      data.table::rbindlist(lapply(m$zon, function(z) {
        data.table::data.table(
          uf = a$cd, mun = m$cd, zona = z$cd,
          secao = vapply(z$sec, `[[`, "", "ns"),
          secao_principal = vapply(z$sec, function(s) if (is.null(s$nsp)) NA_character_ else s$nsp, ""))
      }))
    }))
  }))
}
