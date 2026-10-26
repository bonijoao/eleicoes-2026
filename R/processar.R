# Processa uma seção: lê log e BU, reconstrói os votos dos dois turnos e
# resume a seção numa linha. Erros de leitura viram texto em erro_log/erro_bu,
# nunca derrubam o lote.

processar_secao <- function(log_path, bu_path, agregada = FALSE) {
  tentar <- function(expr) tryCatch(list(v = expr, erro = NA_character_),
                                    error = function(e) list(v = NULL, erro = conditionMessage(e)))
  tem <- function(p) !is.na(p) && file.exists(p)

  bu <- if (tem(bu_path)) tentar(ler_bu(bu_path)) else list(v = NULL, erro = NA_character_)
  ev <- if (tem(log_path)) tentar(eventos_log(ler_linhas_log(log_path))) else list(v = NULL, erro = NA_character_)

  votos <- data.table::data.table()
  v2 <- NULL; n1 <- NA_integer_; incompletos <- NA_integer_; enc_log <- as.POSIXct(NA, tz = "UTC")
  if (!is.null(ev$v)) {
    v1 <- votos_log(ev$v, 1L); v2 <- votos_log(ev$v, 2L)
    n1 <- nrow(v1); incompletos <- attr(v2, "incompletos")
    votos <- data.table::rbindlist(list(v1[, turno := 1L], v2[, turno := 2L]))
    enc <- ev$v[turno %in% 2L & startsWith(msg, "Inicio do Encerramento"), ts_local]
    if (length(enc)) enc_log <- enc[1]
  }
  b <- bu$v
  val <- validar_secao(v2, b, agregada)
  pres <- if (!is.null(b$presidente)) b$presidente else data.table::data.table(tipo = character(), numero = integer(), votos = integer())
  soma <- function(x) if (length(x)) as.integer(sum(x)) else NA_integer_

  secao <- data.table::data.table(
    n_urnas                = if (!is.null(v2)) data.table::uniqueN(v2$id_urna) else NA_integer_,
    abertura_local         = if (!is.null(b)) b$abertura_local else as.POSIXct(NA, tz = "UTC"),
    encerramento_local     = if (!is.null(b)) b$encerramento_local else as.POSIXct(NA, tz = "UTC"),
    encerramento_log_local = enc_log,
    ultimo_voto_local      = if (!is.null(v2) && nrow(v2)) max(v2$ts_fim) else as.POSIXct(NA, tz = "UTC"),
    votos_log              = if (!is.null(v2)) nrow(v2) else NA_integer_,
    votos_log_1t           = n1,
    comparecimento_bu      = if (!is.null(b)) b$comparecimento else NA_integer_,
    aptos                  = if (!is.null(b)) b$aptos else NA_integer_,
    hab_bio                = if (!is.null(b)) unname(b$hab["biometria"]) else NA_integer_,
    hab_manual             = if (!is.null(b)) unname(b$hab["manual"]) else NA_integer_,
    hab_sem                = if (!is.null(b)) unname(b$hab["sem_biometria"]) else NA_integer_,
    pres_13                = soma(pres[numero == 13L, votos]),
    pres_22                = soma(pres[numero == 22L, votos]),
    brancos                = soma(pres[tipo == "branco", votos]),
    nulos                  = soma(pres[tipo == "nulo", votos]),
    incompletos            = incompletos,
    categoria              = val$categoria,
    dif                    = val$dif,
    erro_log               = ev$erro,
    erro_bu                = bu$erro
  )
  list(secao = secao, votos = votos)
}
