# Boletim de urna consolidado do portal de dados abertos do TSE (bweb_*.csv):
# uma linha por seção × cargo × votável. Resume uma linha por seção para o
# cargo de presidente, usada para validar a contagem do 1º turno no log.

ler_bweb <- function(path, cargo = 1L) {
  if (grepl("[.]zip$", path)) {
    d <- tempfile(); on.exit(unlink(d, recursive = TRUE))
    csv <- grep("[.]csv$", utils::unzip(path, list = TRUE)$Name, value = TRUE)[1]
    utils::unzip(path, files = csv, exdir = d)
    path <- file.path(d, csv)
  }
  x <- data.table::fread(path, sep = ";", encoding = "Latin-1",
                         select = c("SG_UF", "CD_MUNICIPIO", "NR_ZONA", "NR_SECAO", "CD_CARGO_PERGUNTA",
                                    "QT_APTOS", "QT_COMPARECIMENTO", "DS_TIPO_URNA"))
  x <- unique(x[CD_CARGO_PERGUNTA == cargo], by = c("SG_UF", "CD_MUNICIPIO", "NR_ZONA", "NR_SECAO"))
  x[, .(uf = tolower(SG_UF), mun = sprintf("%05d", CD_MUNICIPIO), zona = sprintf("%04d", NR_ZONA),
        secao = sprintf("%04d", NR_SECAO), aptos = as.integer(QT_APTOS),
        comparecimento = as.integer(QT_COMPARECIMENTO), tipo_urna = DS_TIPO_URNA)]
}
