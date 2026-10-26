# Download em lote com conexões simultâneas, cache em disco e retentativa.
# Um destino que já existe com tamanho > 0 não é baixado de novo, então rodar
# a coleta outra vez retoma de onde parou. Cada arquivo é escrito em
# <destino>.part e só renomeado quando completo.

UA_PADRAO <- "eleicoes-2026-auditoria (github.com/bonijoao/eleicoes-2026)"

baixar_lote <- function(urls, destinos, conc = 48L, ua = UA_PADRAO,
                        esperas = c(1, 2, 4, 8, 16)) {
  n <- length(urls)
  res <- data.table::data.table(url = urls, destino = destinos, http = NA_integer_,
                                bytes = NA_real_, tentativas = 0L, erro = NA_character_)
  pendentes <- which(!(file.exists(destinos) & file.size(destinos) > 0))
  for (d in unique(dirname(destinos[pendentes]))) dir.create(d, showWarnings = FALSE, recursive = TRUE)

  rodada <- 0L
  while (length(pendentes) > 0L) {
    pool <- curl::new_pool(total_con = conc, host_con = conc)
    repetir <- integer()
    for (i in pendentes) local({
      j <- i
      h <- curl::new_handle(useragent = ua, timeout = 120)
      res$tentativas[j] <<- res$tentativas[j] + 1L
      curl::curl_fetch_multi(urls[j], pool = pool, handle = h,
        done = function(r) {
          res$http[j] <<- r$status_code
          if (r$status_code == 200L) {
            part <- paste0(destinos[j], ".part")
            writeBin(r$content, part)
            file.rename(part, destinos[j])
            res$bytes[j] <<- length(r$content)
            res$erro[j] <<- NA_character_
          } else if (r$status_code >= 500L || r$status_code == 429L) {
            repetir <<- c(repetir, j)
          }
        },
        fail = function(msg) {
          res$erro[j] <<- msg
          repetir <<- c(repetir, j)
        })
    })
    curl::multi_run(pool = pool)
    rodada <- rodada + 1L
    if (rodada > length(esperas)) break
    pendentes <- repetir
    if (length(pendentes) > 0L) Sys.sleep(esperas[rodada])
  }
  res[]
}
