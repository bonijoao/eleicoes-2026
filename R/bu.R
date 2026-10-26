# Boletim de urna (bu.dat), conforme docs/tse/bu.asn1 (ModuloBU, IMPLICIT TAGS).
#
# O arquivo é um EntidadeEnvelopeGenerico; o último campo (conteudo, OCTET
# STRING) traz o DER do EntidadeBoletimUrna, cujos campos são posicionais:
#   1 cabecalho, 2 fase, 3 urna, 4 identificacaoSecao, 5 dataHoraEmissao,
#   6 dadosSecaoSA ([0] DadosSecao), 7 qtdEleitoresCompareceram,
#   [1] detalhamentoComparecimento (opcional), resultadosVotacaoPorEleicao, ...
# Em DadosSecao, "abertura" e "encerramento" são o primeiro e o último voto.

TIPO_VOTO <- c("1" = "nominal", "2" = "branco", "3" = "nulo", "4" = "legenda",
               "5" = "cargo_sem_candidato")
CARGO_PRESIDENTE <- 1L
TIPO_URNA <- c("1" = "secao", "3" = "contingencia", "4" = "reservaSecao", "6" = "reservaEncerrandoSecao")
TIPO_ARQUIVO <- c("1" = "votacaoUE", "2" = "votacaoRED", "3" = "saMistaMRParcialCedula",
                  "4" = "saMistaBUImpressoCedula", "5" = "saManual", "6" = "saEletronica")

# dadosSecaoSA é uma CHOICE: [0] DadosSecao (urna de seção, com primeiro e
# último voto) ou [1] DadosSA (Sistema de Apuração, sem horários).
ler_dados_secao <- function(no) {
  if (no$classe == 2L && no$tag == 0L) {
    list(tipo_bu = "secao",
         abertura = data_hora_je(der_str(no$valor[[1]]$valor)),
         encerramento = data_hora_je(der_str(no$valor[[2]]$valor)))
  } else {
    list(tipo_bu = "sa", abertura = as.POSIXct(NA, tz = "UTC"), encerramento = as.POSIXct(NA, tz = "UTC"))
  }
}

ler_bu <- function(path) {
  env <- der_parse(readBin(path, "raw", file.size(path)))[[1]]$valor
  conteudo <- env[[length(env)]]
  stopifnot(conteudo$classe == 0L, conteudo$tag == 4L)
  bu <- der_parse(conteudo$valor)[[1]]$valor

  secao <- ler_dados_secao(bu[[6]])
  urna <- bu[[3]]$valor
  det <- Filter(function(n) n$classe == 2L && n$tag == 1L, bu[8])
  hab <- if (length(det)) {
    q <- vapply(det[[1]]$valor, function(n) der_int(n$valor), 1L)
    c(biometria = q[2], manual = q[3], sem_biometria = q[1])
  } else c(biometria = NA_integer_, manual = NA_integer_, sem_biometria = NA_integer_)

  resultados <- bu[[if (length(det)) 9L else 8L]]$valor
  pres <- NULL
  aptos <- NA_integer_
  for (r in resultados) {
    rv <- r$valor
    for (res in rv[[5]]$valor) {
      for (cargo in res$valor[[3]]$valor) {
        cod <- cargo$valor[[1]]
        if (cod$classe == 2L && cod$tag == 1L && der_int(cod$valor) == CARGO_PRESIDENTE) {
          aptos <- der_int(rv[[2]]$valor)
          pres <- votos_cargo(cargo$valor[[3]]$valor)
        }
      }
    }
  }

  list(
    tipo_bu            = secao$tipo_bu,
    tipo_urna          = unname(TIPO_URNA[as.character(der_int(urna[[1]]$valor))]),
    tipo_arquivo       = unname(TIPO_ARQUIVO[as.character(der_int(urna[[4]]$valor))]),
    abertura_local     = secao$abertura,
    encerramento_local = secao$encerramento,
    emissao_local      = data_hora_je(der_str(bu[[5]]$valor)),
    comparecimento     = der_int(bu[[7]]$valor),
    hab                = hab,
    presidente         = pres,
    aptos              = aptos
  )
}

# SEQUENCE OF TotalVotosVotavel: [1] tipoVoto, [2] quantidadeVotos,
# [3] identificacaoVotavel {partido, codigo} (ausente em branco e nulo).
votos_cargo <- function(nos) {
  data.table::rbindlist(lapply(nos, function(v) {
    campos <- v$valor
    tag <- vapply(campos, function(n) if (n$classe == 2L) n$tag else -1L, 1L)
    id <- campos[tag == 3L]
    data.table::data.table(
      tipo   = unname(TIPO_VOTO[as.character(der_int(campos[[which(tag == 1L)]]$valor))]),
      numero = if (length(id)) der_int(id[[1]]$valor[[2]]$valor) else NA_integer_,
      votos  = der_int(campos[[which(tag == 2L)]]$valor)
    )
  }))
}

data_hora_je <- function(x) as.POSIXct(x, format = "%Y%m%dT%H%M%S", tz = "UTC")
