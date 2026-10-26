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
