# Leitura do log da urna (.jez). O .jez é um 7z (às vezes zip) com o logd.dat
# em texto Latin-1. Algumas seções trazem outro .jez dentro (por exemplo, o
# log de uma urna substituída), então a leitura é recursiva. Linhas idênticas
# repetidas entre o log interno e o externo são descartadas.

ler_linhas_log <- function(path) {
  linhas <- ler_entradas(readBin(path, "raw", file.size(path)))
  linhas <- linhas[nzchar(linhas)]
  linhas[!duplicated(linhas)]
}

ler_entradas <- function(bytes) {
  f <- tempfile(); on.exit(unlink(f))
  writeBin(bytes, f)
  idx <- archive::archive(f)
  unlist(lapply(seq_len(nrow(idx)), function(k) {
    con <- archive::archive_read(f, file = k, mode = "rb")
    on.exit(close(con))
    x <- readBin(con, "raw", idx$size[k] + 1)
    if (eh_compactado(x)) return(ler_entradas(x))
    x <- x[x != as.raw(0)]
    stringi::stri_split_regex(stringi::stri_encode(x, from = "latin1", to = "UTF-8"), "\r?\n")[[1]]
  }))
}

eh_compactado <- function(x) {
  length(x) >= 2 && (identical(x[1:2], charToRaw("PK")) || identical(x[1:2], charToRaw("7z")))
}
