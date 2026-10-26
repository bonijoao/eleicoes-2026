# Forense eleitoral: levantamento de literatura (2026-10-26)

Notas de trabalho para a fase 2 (testes estatísticos sobre votação por seção).
Os DOIs foram conferidos no Crossref. **[NÃO VERIFICADO]** marca o que veio de
fonte secundária.

## Métodos

| Método | Referência | Ideia | Código | Situação para o Brasil |
|---|---|---|---|---|
| Impressão digital eleitoral | Klimek, Yegorov, Hanel & Thurner (2012), *PNAS* 109(41):16469–73, doi:10.1073/pnas.1210722109 | Histograma 2D de comparecimento × % do vencedor. Fraude incremental ou extrema deforma a "bolha"; modelo estima f_i e f_e | Não há oficial; implementar | **Principal.** Precedente: Klimek & Thurner, *CSH Policy Brief* sobre Brasil 2022 (f_i = f_e = 0, 471.983 unidades, sem revisão por pares) |
| Fraude em seções pequenas | Jiménez, Hidalgo & Klimek (2017), *Science Advances* 3(6):e1602363, doi:10.1126/sciadv.1602363 | Padroniza voto e comparecimento pelos vizinhos geográficos e compara seções pequenas com grandes | Implementar | **Principal.** Lida com a heterogeneidade regional |
| Percentuais inteiros | Kobak, Shpilkin & Pshenichnikov (2016), *Ann. Appl. Stat.* 10(1):54–73, doi:10.1214/16-AOAS904 | Excesso de percentuais redondos contra Monte Carlo binomial | github.com/dkobak/elections (Python) | Controle negativo: mecanismo humano, quase ausente com totalização eletrônica |
| Picos em frações | Rozenas (2017), *Political Analysis* 25(1):41–56, doi:10.1017/pan.2016.9 | Densidade kernel reamostrada | CRAN `spikes` 1.1 (congelado, funciona) | Controle negativo barato |
| Últimos dígitos | Beber & Scacco (2012), *Political Analysis* 20(2):211–34, doi:10.1093/pan/mps003 | χ² uniforme dos últimos dígitos | Trivial em R | Só apêndice. Ver também Medzihorsky (2015), doi:10.1093/pan/mpv021 |
| Benford no 2º dígito | Mebane (2008), em Alvarez, Hall & Hyde (orgs.), *Election Fraud*, Brookings, cap. 10 | Média do 2º dígito ≈ 4,187 | Election Forensics Toolkit (fonte não publicada) | **Evitar como evidência.** Ver a crítica de Deckert, Myagkov & Ordeshook (2011), doi:10.1093/pan/mpr014, e a réplica de Mebane (2011), doi:10.1093/pan/mpr024 |
| eforensics | Ferrari, McAlister & Mebane (2018, working paper MPSA) | Mistura bayesiana com três classes (JAGS) | UMeforensics/eforensics_public (não mantido desde 2020) | **Evitar.** Kim (2026, SocArXiv 6ka47_v1): detecta "fraude" em dados nulos |

## Abordagens "informadas" e validação

- Montgomery, Olivella, Potter & Crisp (2015), *Political Analysis* 23(4):488–505,
  doi:10.1093/pan/mpv023. Combina indicadores com BART.
- Cantú & Saiegh (2011), *Political Analysis* 19(4):409–33, doi:10.1093/pan/mpr033.
  Usa fraude sintética para treinar.
- Zhang, Alvarez & Levin (2019), *PLOS ONE* 14(10):e0223950,
  doi:10.1371/journal.pone.0223950. ML com fraude sintética. É o modelo para a
  validação por injeção.
- Leemann & Bochsler (2014), *Electoral Studies* 35:33–47,
  doi:10.1016/j.electstud.2014.03.005. Implicações múltiplas de cada fraude e
  comparações múltiplas.
- Eggers, Garro & Grimmer (2021), *PNAS* 118(45):e2103619118,
  doi:10.1073/pnas.2103619118. É o melhor modelo de artigo que refuta "anomalias"
  alegadas.

## Brasil

- Figueiredo Filho, Silva & Carvalho (2022), *Forensic Sci. Int.: Synergy* 5:100286,
  doi:10.1016/j.fsisyn.2022.100286. Cinco testes em 2018, sem evidência de fraude.
  Nível de análise **[NÃO VERIFICADO]**.
- Nogueira (2023), *Beijing Law Review* 14(2):727–38, doi:10.4236/blr.2023.142039.
  Último dígito em 2022. A editora tem reputação fraca.
- USP/UFSCar (Shiraishi et al., 11/11/2022), relatório técnico que refuta o
  "Relatório Argentino" e as alegações sobre logs.
- TCU 2022: 4.577 BUs, zero divergências. Número do acórdão **[NÃO VERIFICADO]**.

## Desenho recomendado para a fase 2

1. Fingerprint de Klimek e teste de Jiménez para seções pequenas, com padronização
   por município ou zona.
2. Painel por seção 1T→2T e 2022→2026, com regressão e resíduos espaciais (Gi*).
3. Indicadores dos logs (habilitação manual, rajadas, horário) cruzados com os
   resíduos do item 2. Essa é a contribuição original: não achamos literatura que
   use logs de urna.
4. Kobak e Rozenas como controles negativos.
5. **Validação:**
   - nulos empíricos em 2018 e 2022, com permutações dentro do município;
   - injeção de fraude em 2026 (ballot stuffing, vote stealing, arredondamento),
     variando a fração f (0,1% a 10%), a magnitude e a concentração, nos dois
     sentidos;
   - curvas de poder, reportando o **menor volume fraudado detectável** contra a
     margem.
6. **Pré-registro:** não achamos precedente revisado por pares em forense
   eleitoral. O desenho seria calibrar em 2018/2022, congelar os limiares e aplicar
   a 2026 como holdout, registrado no OSF com o hash do commit.
   - Os dados de 2026 já são públicos, e o pré-registro tem de declarar isso.
7. **Alegação provável a pré-registrar:** a virada ao longo da apuração, que é
   efeito da ordem regional de totalização.

## Periódicos

- *Electoral Studies*: melhor aposta para aplicação com contribuição substantiva.
- *Political Analysis*: exige inovação metodológica.
- *Election Law Journal*.
- *PLOS ONE* e *Statistics and Public Policy*.
- Nacionais: *Brazilian Political Science Review* e *Opinião Pública*.
