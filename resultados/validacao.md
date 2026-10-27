# Validação log × boletim de urna

Gerado em 2026-10-27 12:07 (horário de Brasília). Seções: 517179.

Para cada seção, os votos reconstruídos do log da urna são comparados com o
boletim de urna (BU) assinado: total de comparecimento e forma de habilitação
(biometria, ano de nascimento, sem biometria cadastrada).

## Categorias

| categoria | N | pct |
| --- | --- | --- |
| ok | 497754 | 96.24% |
| agregada |  17931 | 3.47% |
| urna_substituida |   1415 | 0.27% |
| coleta_incompleta |     72 | 0.01% |
| contingencia |      4 | 0.00% |
| nao_explicada |      3 | 0.00% |

Votos conferidos nas seções que batem: 128.233.151 (log) = 128.233.151 (BU).

## Por UF

| uf | agregada | coleta_incompleta | contingencia | nao_explicada | ok | urna_substituida |
| --- | --- | --- | --- | --- | --- | --- |
| ac |  141 |  0 | 0 | 0 |   2267 |   3 |
| al |  145 |  0 | 0 | 0 |   7074 |  27 |
| am |  420 |  0 | 0 | 0 |   8138 |  19 |
| ap |   57 |  0 | 0 | 0 |   1912 |   2 |
| ba | 2474 |  0 | 1 | 1 |  35318 | 156 |
| ce | 1885 |  0 | 0 | 0 |  23695 |  70 |
| df |   81 |  0 | 0 | 0 |   6958 |  11 |
| es |  279 |  0 | 1 | 0 |   9808 |  35 |
| go |  540 |  0 | 0 | 0 |  15653 |  33 |
| ma | 1701 |  0 | 1 | 0 |  18040 |  52 |
| mg | 2131 |  0 | 0 | 0 |  51945 | 117 |
| ms |  178 |  0 | 0 | 0 |   7090 |  16 |
| mt |  688 |  0 | 0 | 0 |   8265 |  22 |
| pa | 1255 |  0 | 0 | 0 |  20776 |  51 |
| pb |  133 |  0 | 0 | 1 |  10671 |  40 |
| pe |  673 |  0 | 0 | 0 |  21357 |  61 |
| pi | 1036 |  0 | 0 | 1 |  10201 |  23 |
| pr |  194 |  0 | 0 | 0 |  27040 | 102 |
| rj | 1063 |  1 | 0 | 0 |  37558 | 116 |
| rn |  221 |  0 | 0 | 0 |   8094 |  21 |
| ro |  243 |  0 | 0 | 0 |   4691 |   7 |
| rr |  108 |  0 | 0 | 0 |   1515 |   4 |
| rs |  191 |  0 | 1 | 0 |  27470 |  76 |
| sc |  232 |  0 | 0 | 0 |  17255 |  71 |
| se |  144 |  0 | 0 | 0 |   5899 |  24 |
| sp |  248 |  1 | 0 | 0 | 103406 | 249 |
| to |  106 |  0 | 0 | 0 |   4380 |   4 |
| zz | 1364 | 70 | 0 | 0 |   1278 |   3 |

## Seções não explicadas

| secao | votos_log | comparecimento_bu | dif | erro_log |
| --- | --- | --- | --- | --- |
| [ba 34711/0021/0178](https://resultados.tse.jus.br/oficial/ele2026/arquivo-urna/3221/dados/ba/34711/0021/0178/p003221-ba-m34711-z0021-s0178-aux.json) | 233 | 234 | -1 | NA |
| [pb 21750/0002/0254](https://resultados.tse.jus.br/oficial/ele2026/arquivo-urna/3221/dados/pb/21750/0002/0254/p003221-pb-m21750-z0002-s0254-aux.json) | 303 | 304 | -1 | NA |
| [pi 11533/0003/0216](https://resultados.tse.jus.br/oficial/ele2026/arquivo-urna/3221/dados/pi/11533/0003/0216/p003221-pi-m11533-z0003-s0216-aux.json) | 258 | 259 | -1 | NA |

## Seções com coleta incompleta

Seções com urna (não agregadas) em que falta o log, o BU ou os dois. O estado
vem do aux.json publicado pelo TSE para a seção.

| local | estado_tse | log | bu | N |
| --- | --- | --- | --- | --- |
| Brasil | Recebido | não | sim |  1 |
| Brasil | Totalizado | não | sim |  1 |
| exterior | Sem arquivo | não | não | 41 |
| exterior | Totalizado | não | não | 29 |

Seções com urna no índice: 499.248. Sem as 41 em estado "Sem arquivo" no TSE: 499.207.
O TSE divulga 499.207 seções instaladas no 2º turno.

## Marcas nas seções analisadas (ok e urna substituída)

| hash não totalizado | fuso suspeito no município | abertura destoa do município | habilitados sem voto |
| --- | --- | --- | --- |
| 14691 | 0 | 84 | 9233 |

## 1º turno: log × BU consolidado do TSE

O 1º turno está no mesmo log da urna e serve de controle nas duas investigações.

| categoria_1t | N |
| --- | --- |
| ok | 497483 |
| urna_diferente_no_1t |   1531 |
| diferente |    155 |

