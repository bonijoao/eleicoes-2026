# Processa uma seção: lê log e BU, reconstrói os votos dos dois turnos e
# resume a seção numa linha. Erros de leitura viram texto em erro_log/erro_bu,
# nunca derrubam o lote.
#
# log_path/bu_path NA significam "não baixado". Com aux_http 404 (ou NA) e
# nada baixado, a seção não tem arquivos no TSE; com aux.json obtido (200) ou
# coleta interrompida (429, 5xx...) e algum arquivo faltando, a coleta ficou
# incompleta e a seção deve ser baixada de novo.

processar_secao <- function(log_path, bu_path, agregada = FALSE, aux_http = NA_integer_,
                            hash_st = NA_character_) {
  tentar <- function(expr) tryCatch(list(v = expr, erro = NA_character_),
                                    error = function(e) list(v = NULL, erro = conditionMessage(e)))
  tem <- function(p) !is.na(p) && file.exists(p)

  bu <- if (tem(bu_path)) tentar(ler_bu(bu_path)) else list(v = NULL, erro = NA_character_)
  ev <- if (tem(log_path)) tentar(eventos_log(ler_linhas_log(log_path))) else list(v = NULL, erro = NA_character_)

  votos <- data.table::data.table()
  v2 <- NULL; n1 <- NA_integer_; tent <- NA_integer_; habs <- NA_integer_
  enc_log <- as.POSIXct(NA, tz = "UTC")
  if (!is.null(ev$v)) {
    v1 <- votos_log(ev$v, 1L); v2 <- votos_log(ev$v, 2L)
    n1 <- nrow(v1)
    tent <- attr(v2, "tentativas_sem_voto"); habs <- attr(v2, "habilitados_sem_voto")
    enc_log <- encerramento_turno(ev$v, v2, 2L)
    votos <- data.table::rbindlist(list(data.table::copy(v1)[, turno := 1L],
                                        data.table::copy(v2)[, turno := 2L]))
  }
  b <- bu$v

  falta <- !tem(log_path) || !tem(bu_path)
  val <- if (isTRUE(agregada) && !tem(log_path) && !tem(bu_path)) {
    list(categoria = "agregada", dif = NA_integer_)
  } else if (!tem(log_path) && !tem(bu_path) && (is.na(aux_http) || aux_http == 404L)) {
    list(categoria = "sem_arquivos", dif = NA_integer_)
  } else if (falta) {
    list(categoria = "coleta_incompleta", dif = NA_integer_)
  } else {
    validar_secao(v2, b, agregada)
  }

  pres <- if (!is.null(b$presidente)) b$presidente else data.table::data.table(tipo = character(), numero = integer(), votos = integer())
  soma <- function(x) if (length(x)) as.integer(sum(x)) else NA_integer_
  de_bu <- function(campo, na) if (!is.null(b)) b[[campo]] else na

  secao <- data.table::data.table(
    aux_http               = as.integer(aux_http),
    hash_st                = hash_st,
    tipo_bu                = de_bu("tipo_bu", NA_character_),
    tipo_urna              = de_bu("tipo_urna", NA_character_),
    tipo_arquivo           = de_bu("tipo_arquivo", NA_character_),
    n_urnas                = if (!is.null(v2)) data.table::uniqueN(v2$id_urna) else NA_integer_,
    abertura_local         = de_bu("abertura_local", as.POSIXct(NA, tz = "UTC")),
    encerramento_local     = de_bu("encerramento_local", as.POSIXct(NA, tz = "UTC")),
    encerramento_log_local = enc_log,
    ultimo_voto_local      = if (!is.null(v2) && nrow(v2)) max(v2$ts_fim) else as.POSIXct(NA, tz = "UTC"),
    votos_log              = if (!is.null(v2)) nrow(v2) else NA_integer_,
    votos_log_1t           = n1,
    log_tem_1t             = if (!is.null(ev$v)) any(format(ev$v$ts_local, "%Y-%m-%d") == "2026-10-04") else NA,
    comparecimento_bu      = de_bu("comparecimento", NA_integer_),
    aptos                  = de_bu("aptos", NA_integer_),
    hab_bio                = if (!is.null(b)) unname(b$hab["biometria"]) else NA_integer_,
    hab_manual             = if (!is.null(b)) unname(b$hab["manual"]) else NA_integer_,
    hab_sem                = if (!is.null(b)) unname(b$hab["sem_biometria"]) else NA_integer_,
    pres_13                = soma(pres[numero == 13L, votos]),
    pres_22                = soma(pres[numero == 22L, votos]),
    brancos                = soma(pres[tipo == "branco", votos]),
    nulos                  = soma(pres[tipo == "nulo", votos]),
    tentativas_sem_voto    = tent,
    habilitados_sem_voto   = habs,
    categoria              = val$categoria,
    dif                    = val$dif,
    erro_log               = ev$erro,
    erro_bu                = bu$erro
  )
  list(secao = secao, votos = votos)
}

# Versão que nunca falha: um erro inesperado vira a categoria
# "erro_processamento" com a mensagem, em vez de derrubar o bloco inteiro.
processar_seguro <- function(log_path, bu_path, ..., .f = processar_secao) {
  tryCatch(.f(log_path, bu_path, ...), error = function(e) list(
    secao = data.table::data.table(categoria = "erro_processamento", erro_log = conditionMessage(e)),
    votos = data.table::data.table()))
}
