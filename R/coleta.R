# Download em lote com conexões simultâneas, cache em disco e retentativa.
# Um destino que já existe com tamanho > 0 não é baixado de novo, então rodar
# a coleta outra vez retoma de onde parou. Cada arquivo é escrito em
# <destino>.part e só renomeado quando completo.
#
# Educação com o servidor: no máximo `taxa` requisições por segundo. Falha de
# rede ou HTTP 5xx espera `esperas[k]` e tenta de novo; HTTP 429 (o CDN do TSE
# bloqueia o IP por alguns minutos) pausa tudo por pausa_429 * 2^(k-1) segundos,
# até max_429 vezes. 404 não se repete.

UA_PADRAO <- "eleicoes-2026-auditoria (github.com/bonijoao/eleicoes-2026)"

baixar_lote <- function(urls, destinos, conc = 16L, ua = UA_PADRAO, taxa = Inf,
                        esperas = c(1, 2, 4, 8, 16), pausa_429 = 120, max_429 = 6L) {
  res <- data.table::data.table(url = urls, destino = destinos, http = NA_integer_,
                                bytes = NA_real_, tentativas = 0L, erro = NA_character_)
  pendentes <- which(!(file.exists(destinos) & file.size(destinos) > 0))
  for (d in unique(dirname(destinos[pendentes]))) dir.create(d, showWarnings = FALSE, recursive = TRUE)

  rodada <- 0L; n429 <- 0L
  while (length(pendentes) > 0L) {
    repetir <- integer(); bloqueado <- integer()
    tamanho <- if (is.finite(taxa)) max(1L, as.integer(ceiling(taxa))) else length(pendentes)
    for (bloco in split(pendentes, ceiling(seq_along(pendentes) / tamanho))) {
      t0 <- Sys.time()
      pool <- curl::new_pool(total_con = conc, host_con = conc)
      for (i in bloco) local({
        j <- i
        res$tentativas[j] <<- res$tentativas[j] + 1L
        curl::curl_fetch_multi(urls[j], pool = pool,
          handle = curl::new_handle(useragent = ua, timeout = 120),
          done = function(r) {
            res$http[j] <<- r$status_code
            if (r$status_code == 200L) {
              part <- paste0(destinos[j], ".part")
              writeBin(r$content, part)
              file.rename(part, destinos[j])
              res$bytes[j] <<- length(r$content)
              res$erro[j] <<- NA_character_
            } else if (r$status_code == 429L) {
              bloqueado <<- c(bloqueado, j)
            } else if (r$status_code >= 500L) {
              repetir <<- c(repetir, j)
            }
          },
          fail = function(msg) {
            res$erro[j] <<- msg
            repetir <<- c(repetir, j)
          })
      })
      curl::multi_run(pool = pool)
      if (length(bloqueado) > 0L) break
      if (is.finite(taxa)) {
        resta <- length(bloco) / taxa - as.numeric(difftime(Sys.time(), t0, units = "secs"))
        if (resta > 0) Sys.sleep(resta)
      }
    }
    if (length(bloqueado) > 0L) {
      n429 <- n429 + 1L
      if (n429 > max_429) break
      espera <- pausa_429 * 2^(n429 - 1L)
      cli::cli_alert_warning("HTTP 429: pausa de {round(espera)} s ({n429}/{max_429})")
      Sys.sleep(espera)
      # o que nem chegou a ser tentado no bloco interrompido volta para a fila
      pendentes <- which(!(file.exists(destinos) & file.size(destinos) > 0) &
                           (is.na(res$http) | res$http %in% c(429L) | res$http >= 500L |
                              !is.na(res$erro)))
      next
    }
    rodada <- rodada + 1L
    if (rodada > length(esperas) || length(repetir) == 0L) break
    pendentes <- repetir
    Sys.sleep(esperas[rodada])
  }
  res[]
}
