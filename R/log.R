# Eventos do log e reconstrução dos votos.
#
# Cada linha do logd.dat tem seis campos separados por TAB:
# data/hora, nível, id da urna, componente, mensagem, hash.
# O relógio é o da urna, no fuso local; guardamos como POSIXct "UTC ingênuo".

DIA_TURNO <- c("04/10/2026" = 1L, "25/10/2026" = 2L)

eventos_log <- function(linhas, dias = names(DIA_TURNO)) {
  linhas <- linhas[substr(linhas, 1, 10) %in% dias]
  campos <- stringi::stri_split_fixed(linhas, "\t", n = 6L, simplify = TRUE)
  e <- data.table::data.table(
    ts_local   = as.POSIXct(campos[, 1], format = "%d/%m/%Y %H:%M:%S", tz = "UTC"),
    nivel      = campos[, 2],
    id_urna    = campos[, 3],
    componente = campos[, 4],
    msg        = campos[, 5],
    dia        = substr(linhas, 1, 10)
  )
  # Turno vigente: o da última aplicação iniciada nesta urna, se for de votação
  # (as de verificação pré/pós não recebem votos) e se o dia for o do turno.
  e[, ordem := .I]
  inicio <- startsWith(e$msg, "Iniciando aplicação")
  turno_app <- rep(NA_integer_, nrow(e))
  turno_app[inicio] <- -1L
  com_turno <- inicio & !grepl("VERIFICA", e$msg, fixed = TRUE)
  turno_app[com_turno] <- as.integer(stringi::stri_match_first_regex(e$msg[com_turno], "(\\d)º turno")[, 2])
  turno_app[inicio & is.na(turno_app)] <- -1L
  e[, turno := turno_app]
  e[, turno := data.table::nafill(turno, "locf"), by = id_urna]
  e[turno == -1L | turno != DIA_TURNO[dia], turno := NA_integer_]
  e[, c("dia", "ordem") := NULL]
  e[]
}

votos_log <- function(eventos, turno) {
  t_alvo <- turno
  e <- eventos[!is.na(turno) & turno == t_alvo]
  e[, voto := cumsum(startsWith(msg, "Identificador do eleitor digitado pelo mesário")), by = id_urna]
  e <- e[voto > 0L]
  tent <- as.integer(stringi::stri_match_first_regex(e$msg, "^Solicita digital\\. Tentativa \\[(\\d+)\\]")[, 2])
  e[, tent := tent]
  v <- e[, .(
    ts_ini       = ts_local[1],
    ts_fim       = ts_local[msg == "O voto do eleitor foi computado"][1],
    manual       = any(startsWith(msg, "Solicitação de dado pessoal do eleitor para habilitação manual")),
    digital      = any(!is.na(tent)),
    n_tentativas = if (any(!is.na(tent))) max(tent, na.rm = TRUE) else 0L
  ), by = .(id_urna, voto)]
  incompletos <- sum(is.na(v$ts_fim))
  v <- v[!is.na(ts_fim)]
  v[, tipo_hab := data.table::fifelse(manual, "manual",
                    data.table::fifelse(digital, "biometria", "sem_biometria"))]
  v <- v[, .(id_urna, ts_ini, ts_fim, tipo_hab, n_tentativas)]
  data.table::setattr(v, "incompletos", incompletos)
  v[]
}
