# Investigação 2: "voto espírita"

Gerado em 2026-10-27 20:26 (horário de Brasília). Método: `PREREGISTRO.md`, seção 4, e `DESVIOS.md`.

**Alegação:** mesários teriam votado no lugar de eleitores ausentes. Isso deixaria
excesso de habilitação manual ou sem biometria, concentrado no fim do dia e em votos
seguidos e rápidos.

## Seções

Analisadas: 499.169 (categorias `ok` e `urna_substituida`). Com controle pelo 1º turno: 497.483.
Com horário confiável (métrica 3): 497.804.

## Métrica 1: taxa de habilitação manual por seção

| turno | mediana | p90 | p99 | p99,9 |
| --- | --- | --- | --- | --- |
| 2º turno | 0,061 | 0,118 | 0,193 | 0,282 |
| 1º turno | 0,061 | 0,116 | 0,191 | 0,284 |

## Métrica 2: escore de excesso

Sobredispersão φ = 1,67 (manual) e 0,41 (sem biometria); placebo: 3,75 e 8,33.
Seções com esperado zero e habilitação manual no 2º turno (sem escore): 0.

| escore | p50 | p99 | p99,9 | z > 4 |
| --- | --- | --- | --- | --- |
| z, 2º turno | -0,02 | 2,63 | 4,02 | 510 |
| z, placebo | -0,10 | 2,82 | 4,73 | 1.022 |

## Sinais

Rajada: δ = 47 s, fixado pelo 1º turno antes da análise do 2º (`resultados/rajada_delta.json`).

| sinal | 2º turno, todas | 2º turno, com controle | 1º turno (placebo) |
| --- | --- | --- | --- |
| 1: excesso de habilitação manual (z > 4) | 510 | 510 | 1.022 |
| 1b: excesso de sem biometria (z > 4) | 246 | 246 | 4.129 |
| 2: manual concentrada no fim do dia | 3 | 3 | 8 |
| 3: rajada de 10 votos ou mais | 46.009 | 45.829 | 28 |
| dois ou mais sinais | 58 | 58 | 3 |

Combinações nas seções do 2º turno com dois ou mais sinais:

| sinais | N |
| --- | --- |
| 1 3 | 45 |
| 1b 3 | 12 |
| 1 1b |  1 |

### O sinal 3 não separa nada no 2º turno

O limiar δ saiu do 1º turno, como pré-registrado. A cédula do 2º turno é bem mais curta,
então cada eleitor leva menos tempo na urna e intervalos abaixo de δ viram rotina:

| turno | intervalo mediano (s) | intervalos abaixo de δ |
| --- | --- | --- |
| 1º turno | 101 | 0,09% |
| 2º turno | 70 | 23,08% |

Por isso o sinal 3 aparece em dezenas de milhares de seções no 2º turno e quase nenhuma no
placebo, e a comparação com o placebo não vale para ele. A hora em que as rajadas do 2º
turno começam (Brasília) mostra fila de manhã, não votos no fim do dia:

| hora | rajadas |
| --- | --- |
| 08h | 27.364 |
| 09h | 13.272 |
| 10h | 10.827 |
| 11h | 5.325 |
| 12h | 1.400 |
| 13h | 322 |
| 14h | 204 |
| 15h | 148 |
| 16h | 57 |

As contas pré-registradas não mudam. Por UF: `resultados/rajada_diagnostico_uf.csv`.

## A favor de quem?

Nas seções do 2º turno com dois ou mais sinais, o saldo Flávio − Lula observado e o
esperado pelas proporções do município:

| secoes | saldo_22_13_observado | saldo_22_13_esperado |
| --- | --- | --- |
| 58 | -3.931 | -3.380 |

## Como ler

- Indício compatível com a alegação seria um número de seções com dois ou mais sinais
  muito acima do placebo do 1º turno, concentrado a favor de um candidato.
- Uma seção isolada fora da curva não prova nada: com ~500 mil seções, alguns extremos
  são esperados por acaso e por problemas operacionais.
- As seções com dois ou mais sinais são examinadas uma a uma em `resultados/voto_espirita_casos.md`.
- Lista completa das seções com algum sinal: `resultados/voto_espirita_sinais.csv`.

