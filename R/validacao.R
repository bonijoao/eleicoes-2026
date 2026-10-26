# Confronto entre os votos reconstruídos do log e o boletim de urna da seção.
# Espera-se igualdade exata no total e na forma de habilitação; toda exceção
# conhecida tem categoria própria, e o resto é "nao_explicada" (um achado).

validar_secao <- function(votos, bu, agregada = FALSE) {
  if (is.null(bu) && is.null(votos)) {
    return(list(categoria = if (isTRUE(agregada)) "agregada" else "sem_arquivos", dif = NA_integer_))
  }
  if (is.null(votos)) return(list(categoria = "bu_sem_log", dif = NA_integer_))
  if (is.null(bu)) return(list(categoria = "log_sem_bu", dif = NA_integer_))

  dif <- nrow(votos) - bu$comparecimento
  hab_log <- c(biometria = sum(votos$tipo_hab == "biometria"),
               manual = sum(votos$tipo_hab == "manual"),
               sem_biometria = sum(votos$tipo_hab == "sem_biometria"))
  hab_ok <- anyNA(bu$hab) || all(hab_log == bu$hab[names(hab_log)])

  categoria <- if (dif != 0L || !hab_ok) "nao_explicada"
               else if (data.table::uniqueN(votos$id_urna) > 1L) "urna_substituida"
               else "ok"
  list(categoria = categoria, dif = as.integer(dif))
}
