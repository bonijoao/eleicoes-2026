# Lê o aux.json (manifesto) de uma seção e escolhe, entre os hashes
# publicados, o totalizado mais recente. Sem arquivo, devolve só n_hashes = NA e
# hash_st = NA (sem o campo hash: use x[["hash"]], porque x$hash casaria com
# hash_st). O arquivo não se chama aux.R porque "aux" é nome reservado no Windows.

ler_aux <- function(path) {
  if (!file.exists(path)) return(list(n_hashes = NA_integer_, hash_st = NA_character_))
  h <- jsonlite::fromJSON(path, simplifyVector = FALSE)$hashes
  if (length(h) == 0L) return(list(n_hashes = 0L, hash_st = NA_character_))
  quando <- vapply(h, function(x) paste(substr(x$dr, 7, 10), substr(x$dr, 4, 5),
                                        substr(x$dr, 1, 2), x$hr), "")
  st <- vapply(h, `[[`, "", "st")
  esc <- h[[order(st == "Totalizado", quando, decreasing = TRUE)[1]]]
  nm <- vapply(esc$arq, `[[`, "", "nm")
  tp <- vapply(esc$arq, `[[`, "", "tp")
  list(n_hashes = length(h), hash_st = esc$st, hash = esc$hash,
       log = nm[tp == "log"][1], bu = nm[tp == "bu"][1])
}
