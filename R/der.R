# Leitor mínimo de DER (ASN.1), suficiente para os arquivos de urna do TSE.
# Cada nó é list(classe, construido, tag, valor): classe 0 = universal,
# 2 = contexto; valor é raw (primitivo) ou lista de nós filhos (construído).

der_parse <- function(x, ini = 1L, fim = length(x)) {
  nos <- list()
  i <- ini
  while (i <= fim) {
    b <- as.integer(x[i]); i <- i + 1L
    classe <- b %/% 64L
    construido <- (b %/% 32L) %% 2L == 1L
    tag <- b %% 32L
    if (tag == 31L) {
      tag <- 0L
      repeat {
        c <- as.integer(x[i]); i <- i + 1L
        tag <- tag * 128L + c %% 128L
        if (c < 128L) break
      }
    }
    len <- as.integer(x[i]); i <- i + 1L
    if (len >= 128L) {
      nb <- len - 128L
      len <- sum(as.integer(x[i:(i + nb - 1L)]) * 256^((nb - 1L):0))
      i <- i + nb
    }
    a <- i; z <- i + len - 1L
    valor <- if (construido) der_parse(x, a, z) else if (len > 0L) x[a:z] else raw()
    nos[[length(nos) + 1L]] <- list(classe = classe, construido = construido, tag = tag, valor = valor)
    i <- z + 1L
  }
  nos
}

# INTEGER/ENUMERATED: inteiro com sinal, big-endian.
der_int <- function(v) {
  n <- as.integer(v)
  r <- sum(n * 256^((length(n) - 1L):0))
  if (length(n) > 0L && n[1] >= 128L) r <- r - 256^length(n)
  as.integer(r)
}

der_str <- function(v) rawToChar(v)
