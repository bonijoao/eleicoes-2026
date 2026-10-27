# Desvios em relação ao pré-registro

Mudanças feitas depois do commit do `PREREGISTRO.md`, com data e motivo.

## 2026-10-26: categorias de validação a mais (antes de qualquer análise)

Uma revisão de código feita no mesmo dia, antes da coleta nacional terminar e antes de
qualquer análise, apontou situações que o pipeline jogava em "sem arquivos" ou
"não explicada" sem distinguir a causa. A seção 1 do pré-registro previa as categorias
`ok`, `urna_substituida`, `agregada` e `nao_explicada`. Foram acrescentadas:

| Categoria | O que é | Tratamento |
|---|---|---|
| `coleta_incompleta` | o download falhou (bloqueio do servidor, erro de rede) | baixar de novo; não entra na análise até ser resolvida, e a contagem final é publicada |
| `apuracao_sa` | BU de Sistema de Apuração (votos em cédula) | fora das análises baseadas no log, com contagem publicada |
| `contingencia` | urna de contingência ou BU recuperado (RED) cujo log não bate com o BU | fora, com contagem publicada; se bater, segue como `ok` |
| `erro_processamento` | erro inesperado ao ler a seção | fora, listada com a mensagem |

**Controle pelo 1º turno.** O pré-registro usa o 1º turno da mesma seção como controle.
O log do 1º turno passa a ser validado contra o boletim de urna consolidado do 1º turno
(portal de dados abertos do TSE). Uma categoria nova, `urna_diferente_no_1t`, cobre as
seções cuja urna do 2º turno não foi a do 1º: o log não tem nenhum registro de 04/10.
Nessas seções não há controle, e elas ficam fora **só** das métricas que dependem do
1º turno (investigação 1, métrica 2; investigação 2, métrica 2 e placebo). Na amostra de
validação foram 5 de 1.928 seções com urna.

**Fuso.** Municípios com offset fora do admissível para a UF ou com menos de 3 seções
ficam marcados (`fuso_suspeito`), e seções cuja hora do primeiro voto destoa do
município também (`abertura_destoa`). As duas marcas se juntam à regra
`confianca_offset < 0,8`: seções marcadas são analisadas à parte nas métricas por
horário.

**Votos não concluídos.** A contagem foi separada em `tentativas_sem_voto` (identificador
digitado que não virou voto, por exemplo título errado) e `habilitados_sem_voto` (a urna
habilitou o eleitor e o voto não foi computado). Só a segunda descreve um voto iniciado e
não concluído.

## 2026-10-27: como as contas em aberto serão feitas (antes de rodar as análises)

A validação nacional já foi publicada (`resultados/validacao.md`). Nenhum número das
investigações 1 e 2 foi visto. O pré-registro deixa algumas contas sem detalhe; elas
ficam fixadas aqui antes de rodar.

**Pré-condição.** São 3 seções não explicadas em 499.248 com urna (0,0006%), abaixo
do limite de 0,1%. As análises seguem.

**Cortes de horário.** "Depois das 17h00" é estritamente depois de 17:00:00; o mesmo
vale para 17h03. "A partir das 16h00" inclui 16:00:00.

**Seções sem controle pelo 1º turno.** Além de `urna_diferente_no_1t`, ficam fora das
métricas que dependem do 1º turno as seções em que o log do 1º turno não bate com o
BU consolidado (`diferente`, 155 seções) e as que não têm BU do 1º turno.

**Investigação 1.**

- Os quintis de eleitores aptos do critério de reserva são calculados dentro de cada
  UF, sobre as seções do grupo B com controle.
- Uma mediana `r_m` negativa é usada como está, porque o pré-registro não a corta; o
  número de municípios com `r_m < 0` é publicado.
- `p13_m` e `p22_m` são as proporções de cada candidato nos votos válidos (13 + 22)
  do município, no BU do 2º turno, em todas as seções com urna.

**Investigação 2.**

- **Encolhimento.** `p_i = (manual_1T + κ_UF × m_mun) / (comp_1T + κ_UF)`, em que
  `m_mun` é a taxa manual do município no 1º turno. `κ_UF` sai pelo método dos
  momentos: `ρ = média_i[((x_i − m)² / (m(1 − m)) − 1/n_i) / (1 − 1/n_i)]`, truncado
  em [0,000001; 0,999], e `κ = 1/ρ − 1`.
- **Sobredispersão.** `φ` é a soma dos quadrados dos resíduos de Pearson,
  `(manual_2T − E) / sqrt(E(1 − p))`, dividida por `n − 1`, nas seções com `E > 0`.
  Seções com `E = 0` ficam sem escore e são listadas à parte se tiverem habilitação
  manual no 2º turno.
- **Rajadas.** O intervalo é medido em segundos entre votos computados consecutivos da
  mesma urna e do mesmo turno. `δ` é o menor valor `d` tal que pelo menos 0,1% dos
  intervalos do 1º turno no Brasil (sem o exterior) são `≤ d`. O Sinal 3 exige 9 ou
  mais intervalos seguidos `< δ`, ou seja, 10 votos. Se `δ` for 0, nenhum intervalo
  fica abaixo dele, e isso é publicado.
- **Placebo no 1º turno.** A taxa esperada de cada seção é a taxa manual do 1º turno
  no município **sem a própria seção**, sem encolhimento. O Sinal 2 usa as 16h00 de
  04/10, e o Sinal 3 usa o mesmo `δ`.
- **"Favorecer um candidato".** Nas seções com dois ou mais sinais, o saldo observado
  `Σ(votos 22 − votos 13)` é comparado com o esperado pelas proporções do município,
  `Σ válidos_i × (p22_m − p13_m)`, e a diferença é publicada.

## 2026-10-27: o sinal 3 não discrimina no 2º turno (diagnóstico, sem mudar contas)

Com `δ = 47 s`, fixado pelo 1º turno e publicado antes da leitura do 2º, o Sinal 3
apareceu em 46.009 seções do 2º turno e em 28 no placebo do 1º. A causa é a cédula:
a do 2º turno é bem mais curta, e o intervalo mediano entre votos cai de 101 s para
70 s. Abaixo de `δ` ficam 0,09% dos intervalos do 1º turno e 23% dos do 2º.

O que foi feito, depois de ver esses números:

- As contas pré-registradas não mudam. O Sinal 3 e a contagem de "dois ou mais
  sinais" são publicados como saíram.
- Um diagnóstico descritivo (`scripts/07b_rajada_diagnostico.R`) publica os
  intervalos por turno e por UF e a hora de Brasília em que cada rajada começa. Ele
  não cria teste novo nem muda limiar.
- O relatório diz que a comparação com o placebo não vale para o Sinal 3.

Nenhuma análise de sensibilidade com outro `δ` foi feita.
