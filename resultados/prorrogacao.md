# Investigação 1: a prorrogação até as 19h

Gerado em 2026-10-27 19:30 (horário de Brasília). Método: `PREREGISTRO.md`, seção 3, e `DESVIOS.md`.

**Pergunta:** quantos votos, no máximo, poderiam ter sido perdidos nas seções que já
tinham encerrado quando a decisão saiu (17h03 de Brasília), e esse número chega perto
da margem de 4.430.191 votos?

## Seções

| grupo | secoes |
| --- | --- |
| analisadas | 497.804 |
| A: encerrada até 17h03 | 132.502 |
| B: encerrada depois de 17h03 | 365.290 |
| sem encerramento no log | 12 |
| B com controle pelo 1º turno | 364.077 |
| analisadas à parte (fuso incerto) | 84 |

Ficam fora o exterior e as seções fora das categorias `ok` e `urna_substituida`.

## Métrica 1: votos depois das 17h00 e das 17h03

| turno | depois das 17h00 | depois das 17h03 |
| --- | --- | --- |
| 2º turno (25/10) | 34.038 | 7.906 |
| 1º turno (04/10) | 3.707.262 | 3.398.534 |

No 2º turno, as seções analisadas somam 127.833.399 votos. Por UF: `resultados/prorrogacao_uf.csv`.

## Métrica 2: efeito da prorrogação nas seções B

Taxa de votos depois das 17h00 por eleitor apto no 2º turno, menos a mesma taxa no 1º
turno, quando não houve prorrogação.

| estatistica | efeito |
| --- | --- |
| média | -0,0228 |
| p5 | -0,1277 |
| p25 | -0,0213 |
| mediana | 0,0000 |
| p75 | 0,0000 |
| p95 | 0,0000 |

## Métrica 3: teto do voto perdido nas seções A

| camada | votos | % da margem | premissas |
| --- | --- | --- | --- |
| bruto | -381.236 | — | eleitores aptos das seções A × mediana do efeito nas seções B parecidas |
| líquido para Flávio | 112.240 | 2,5% | bruto × (proporção de Flávio − proporção de Lula) no município |
| pior caso | 19.824 | 0,4% | eleitores aptos das seções A × percentil 95 do efeito na UF; todos votariam em Flávio |

Taxa de referência das seções A: 130.208 pelo município, 2.294 por UF e quintil de aptos, 0 sem taxa.
Municípios com mediana do efeito negativa: 2.343 de 5.228.

O bruto é negativo: nas seções B, a taxa de votos depois das 17h00 no 2º turno ficou, em geral,
abaixo da do 1º turno. Com o bruto negativo, o líquido não mede votos perdidos; o sinal dele
só reflete se o município pende para Lula ou para Flávio. O teto que responde à pergunta é o
pior caso.

## Seções analisadas à parte (fuso incerto)

84 seções (A: 17; B: 67). Mesmas contas:

| camada | votos | % da margem | premissas |
| --- | --- | --- | --- |
| bruto | -169 | — | eleitores aptos das seções A × mediana do efeito nas seções B parecidas |
| líquido para Flávio | 65 | 0,0% | bruto × (proporção de Flávio − proporção de Lula) no município |
| pior caso | -142 | -0,0% | eleitores aptos das seções A × percentil 95 do efeito na UF; todos votariam em Flávio |

