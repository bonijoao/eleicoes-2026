# Desenho do projeto

## Por quê

No 2º turno de 25/10/2026, Lula foi reeleito com 51,79% dos votos válidos contra
48,21% de Flávio Bolsonaro, uma margem de cerca de 4,4 milhões de votos. O lado
derrotado alega fraude. Este projeto pega alegações **concretas** e verifica, nos
arquivos públicos de cada urna, se aparece a marca que elas deixariam.

Não afirmamos "provamos que não houve fraude": isso não se prova com dados. A
forma é outra. A alegação X deixaria a marca Y nos dados; medimos Y; aqui está o
resultado, e aqui está o código para você refazer a conta. Os testes e limiares
foram registrados em [`PREREGISTRO.md`](../PREREGISTRO.md) antes da análise
nacional.

## O que é testado

1. **Prorrogação até as 19h.** A decisão saiu às 17h03 de Brasília e valeu só para
   urnas ainda abertas. Quantos votos poderiam ter sido perdidos nas seções já
   encerradas, e esse número chega perto da margem?
2. **"Voto espírita".** Mesários votando no lugar de eleitores ausentes deixariam
   rastro no log da urna: liberação manual (por ano de nascimento) em excesso,
   concentrada no fim do dia, e votos em rajada.
3. **Validação cruzada.** Para cada seção, os votos reconstruídos do log batem com
   o boletim de urna assinado?

## Dados

Para cada seção, o TSE publica em
`resultados.tse.jus.br/oficial/ele2026/arquivo-urna/` estes arquivos:

- o **log** da urna (`.jez`), com cada evento registrado com hora;
- o **boletim de urna** (`bu.dat`, ASN.1/DER, especificação em
  [`docs/tse/`](tse/));
- o registro digital do voto.

Detalhes que importam:

- **Relógio:** a urna registra no fuso local. O fuso de cada município é inferido
  pelo horário do primeiro voto, já que a votação abre às 8h de Brasília em todo o
  país. No exterior não há conversão.
- **Turnos:** o log acumula preparação, 1º e 2º turnos. O 1º turno da mesma urna
  serve de controle natural.
- **Seções agregadas:** não têm urna própria. O índice do TSE indica a seção
  principal em que os eleitores delas votam.
- **Urna substituída no dia:** o log traz o log da urna anterior dentro do arquivo.
- **Urna ligada na véspera:** algumas não reiniciam a aplicação no dia da eleição.

## Como roda

A coleta e o processamento usam um pacote R pequeno (`R/`, com testes em
`tests/testthat/`) e scripts numerados (`scripts/`):

| Script | O que faz |
|---|---|
| `01_indice.R` | índice de seções por UF |
| `02_coletar.R` | download de logs e BUs, com cache, retomada e limite de requisições por segundo; o servidor do TSE bloqueia IPs que exageram |
| `03_processar.R` | uma tabela de seções e uma de votos, em Parquet |
| `04_validar.R` | relatório log × BU (`resultados/`) |

O ambiente R é reproduzível com `renv::restore()`.
