# Pré-registro: investigações 1 e 2

**Aprovado em 26/10/2026 e publicado antes da coleta e da análise nacionais.** A data
e o hash do commit que introduz este arquivo são a garantia de que os testes e os
limiares abaixo foram escolhidos antes de vermos os resultados.

Autor: João Paulo Bonifácio. Dados: arquivos de urna do 2º turno de 25/10/2026,
publicados pelo TSE em `resultados.tse.jus.br` (log, boletim de urna) para cada
seção.

## 0. O que já vimos antes de escrever isto

Por transparência, este é tudo o que já vimos dos dados:

- **Amostra de validação.** 2.000 seções sorteadas (semente 2026) foram usadas só
  para testar o pipeline. Nessa amostra:
  - o número de votos reconstruído do log bateu exatamente com o BU em todas as
    seções com urna;
  - as habilitações se dividiram em ~90% por biometria, ~6% por ano de nascimento
    e ~4% sem biometria cadastrada;
  - não olhamos a distribuição por seção, por horário nem por candidato.
- **Exploração inicial.** Num teste de velocidade com 400 seções de SP, vimos a
  contagem de votos por hora (23 votos às 17h e 1 às 18h no horário de SP).
- **Seção usada como exemplo.** Os números da seção 01074/0004/0001 (AC) aparecem
  nos testes.

Nenhum outro número das investigações foi visto.

## 1. Pré-condição: validação nacional

Antes de qualquer análise, o pipeline compara, para cada seção, os votos do log com
o comparecimento e a forma de habilitação do BU (`resultados/validacao.md`).

- **O que entra na análise:** seções nas categorias `ok` e `urna_substituida`.
- **O que fica fora, com contagem publicada:**
  - `agregada`: não tem urna própria;
  - `nao_explicada`: cada uma é listada com link para os arquivos do TSE;
  - erros de leitura.
- **Limite:** se `nao_explicada` passar de 0,1% das seções com urna, paramos e
  publicamos isso antes de seguir.

## 2. Definições comuns

- **Horário de Brasília.**
  - O relógio da urna está no fuso local. O offset de cada município é
    `8 − moda(hora do primeiro voto no BU)`.
  - Seções de municípios com `confianca_offset < 0,8` são analisadas à parte.
  - O exterior (`zz`) fica fora das análises por horário, porque lá a votação
    segue o horário local de cada país.
- **Voto:** sequência do log que termina em "O voto do eleitor foi computado",
  com horário `ts_fim`.
- **Encerramento da seção:** primeiro evento "Inicio do Encerramento" do 2º turno
  no log (`encerramento_log_bsb`).
- **Margem oficial:** votos de Lula menos votos de Flávio no 2º turno
  (64.256.232 − 59.826.041 = 4.430.191).

## 3. Investigação 1: a prorrogação até as 19h

**Alegação:** a decisão do ministro Zanin, publicada às 17h03 de Brasília, estendeu a
votação só onde a urna ainda estava aberta. Nos locais já encerrados, eleitores de
Flávio teriam perdido o direito de votar, em número capaz de mudar o resultado.

**Pergunta:** quantos votos, no máximo, poderiam ter sido perdidos nas seções já
encerradas, e esse número chega perto da margem?

**Grupos de seções:**
- **A, encerrada antes da decisão:** `encerramento_log_bsb ≤ 17:03:00`.
- **B, aberta depois da decisão:** `encerramento_log_bsb > 17:03:00`. Pode ser por
  fila ou pela prorrogação.

**Métricas:**

1. **Votos depois das 17h00 e depois das 17h03**, por seção, UF e Brasil, nos dois
   turnos.
2. **Efeito da prorrogação, com o 1º turno como controle.** Para cada seção de B,
   calcula-se a taxa de votos depois das 17h00 por eleitor apto no 2º turno menos
   a mesma taxa no 1º turno, quando não houve prorrogação. Relatamos a média e a
   distribuição.
3. **Teto do voto perdido nas seções do grupo A**, em três camadas:
   - **Bruto:** `N = Σ_A aptos_i × r_m`.
     - `r_m` é a mediana da métrica 2 nas seções B do mesmo município.
     - Com menos de 5 seções B no município, usa-se a mediana das seções B da mesma
       UF e do mesmo quintil de eleitores aptos.
   - **Líquido para Flávio:** `Σ_A aptos_i × r_m × (p22_m − p13_m)`, em que `p` é
     a proporção de votos válidos de cada candidato no município, no 2º turno.
   - **Pior caso**, generoso de propósito com a alegação:
     - `r` é o percentil 95 da métrica 2 nas seções B da UF;
     - 100% desses eleitores votariam em Flávio;
     - o saldo é igual a `N`.

**Leitura:**
- Só os valores líquido e de pior caso são comparados com a margem de 4.430.191.
- Publicamos os três valores, e as premissas acompanham sempre o número.
- **Não há limiar de "fraude" nesta investigação.** O resultado é uma conta
  aberta. Se o pior caso passar de 50% da margem, dizemos isso com destaque.

## 4. Investigação 2: "voto espírita"

**Alegação:** mesários teriam votado no lugar de eleitores ausentes.

**Mecanismo e marca esperada.**
- Num eleitor ausente com biometria cadastrada, a digital não bate. O mesário
  precisaria liberar o voto pelo ano de nascimento (habilitação manual).
- Num eleitor ausente sem biometria cadastrada, o mesário só digita o título.
- Se isso acontecesse em escala, esperaríamos seções com excesso de habilitação
  manual ou sem biometria, concentrado no fim do dia e em votos seguidos e rápidos.

**Métricas, por seção (log e BU):**

1. `taxa_manual` = habilitações por ano de nascimento ÷ comparecimento, nos dois
   turnos.
2. **Excesso em relação ao 1º turno**, com o 1º turno da mesma seção como
   referência:
   - valor esperado: `E_i = comparecimento_2T × p_i`;
   - `p_i` é a taxa manual da seção no 1º turno, encolhida para a taxa do
     município por Bayes empírico beta-binomial, com parâmetros estimados por UF;
   - escore: `z_i = (manual_2T − E_i) / sqrt(φ × E_i × (1 − p_i))`;
   - `φ` é a sobredispersão estimada nacionalmente (Pearson, sobre todas as
     seções).
   - **Sinal 1:** `z_i > 4`.
3. **Concentração no fim do dia:**
   - fração das habilitações manuais da seção feitas a partir das 16h00 de
     Brasília, comparada com a fração de todos os votos da seção feitos a partir
     das 16h00;
   - **Sinal 2:** diferença maior que 0,5 em seções com pelo menos 10 habilitações
     manuais.
4. **Rajadas:**
   - intervalo entre votos computados consecutivos na mesma urna;
   - o limiar `δ` é o percentil 0,1 dos intervalos do **1º turno** no país,
     calculado antes de abrir os do 2º turno;
   - **Sinal 3:** 10 ou mais votos seguidos com intervalo menor que `δ`.
5. **Mesmo cálculo para "sem biometria".** Repete-se a métrica 2 com a taxa de
   eleitores sem biometria cadastrada (**Sinal 1b**).

**Leitura:**
- Publicamos a distribuição nacional de cada métrica e a lista completa das seções
  com algum sinal, com link para os arquivos do TSE.
- Uma seção com **dois ou mais sinais** é examinada caso a caso no log: falha de
  leitor biométrico, troca de urna, queda de energia. Publicamos o que encontrarmos,
  inclusive "sem explicação".
- Por acaso, esperamos poucas dezenas de seções com `z > 4` em ~500 mil.
- **O que contaria como indício compatível com a alegação:** um número de seções
  com dois ou mais sinais muito acima do observado no 1º turno com as mesmas regras
  (o 1º turno serve de "placebo", calculado com p_i vindo do próprio 1º turno em
  validação cruzada), concentrado de forma a favorecer um candidato.
- **O que não conta como prova de nada:** uma seção isolada fora da curva. Com 500
  mil seções, alguns extremos são esperados por acaso e por problemas operacionais.

## 5. Compromissos

- Todos os resultados deste documento são publicados, inclusive os que não
  favorecem a leitura do autor.
- **Mudanças de método depois deste commit** são registradas em `DESVIOS.md`, com
  data e motivo, e a versão pré-registrada também é reportada.
- O código que gera cada número fica neste repositório, e qualquer pessoa pode
  rodá-lo a partir dos arquivos públicos do TSE.
