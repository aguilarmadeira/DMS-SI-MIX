# MORAP-NM — Data freeze e verificação prévia (Protocolo v2.1, §4.2–4.3)

**Data:** 2026-07-26 (rev. 2 — convenções congeladas com o autor). Bloqueio do §4.2 levantado: Tabela 2 de Cao et al. (2013) obtida do PDF original e transcrita verbatim.

## Convenções congeladas (aprovadas pelo autor)

- **F₁ = 1 − R_sys** (transformação afim estritamente decrescente de R: preserva exatamente a ordem Pareto da maximização de fiabilidade; objetivos todos não-negativos; o HV com r = z_nad + δ(z_nad − z_ideal) é invariante por translação, logo nenhuma métrica é afetada); F₂ = C_sys, F₃ = W_sys.
- **Ordem de variáveis intercalada (z₁, n₁, z₂, n₂, z₃, n₃)** = (K, D, K, D, K, D).
- **Rótulos 'Si_Tj'**; objetivos calculados por *lookup de rótulo* (não por posição) — imune ao reordenamento de posições do teste B3b.
- **Dois objetos na enumeração** (§8 do autor): 𝒫⋆_dec (decisões Pareto-ótimas — recuperação de configurações, tipos/níveis por subsistema, first-hit) e ℱ⋆_obj (vetores objetivo distintos não-dominados — HV, HV gap, IGD, recall/precisão objetivos). Nesta instância coincidem em cardinalidade (578/578), mas o enumerador devolve ambos por princípio.
- **BibTeX**: CaoMuratChinnam2013 (dados, DOI 10.1016/j.ress.2012.09.013) + TaboadaCoit2012 (origem da instância, IJAEC 3(2):1–18).

## Fonte

D. Cao, A. Murat, R. B. Chinnam, "Efficient exact optimization of multi-objective redundancy allocation problems in series-parallel systems", *Reliability Engineering & System Safety* 111 (2013) 154–163, DOI 10.1016/j.ress.2012.09.013 — Tabela 2. A instância provém de Taboada & Coit (2012), *Int. J. Applied Evolutionary Computation* 3(2):1–18 (ref. [30] de Cao). Estrutura: s = 3, m = (5, 4, 5), n_max = 7 nos três subsistemas. Nota de citação: a linhagem dos dados é Taboada & Coit **2012** (não o artigo de 2007 [23]).

## Dados congelados (r, c, w por tipo)

| S | tipo | r | c | w |
|---|---|---|---|---|
| 1 | 1 | .94 | 9 | 9 |
| 1 | 2 | .91 | 6 | 6 |
| 1 | 3 | .89 | 6 | 4 |
| 1 | 4 | .75 | 3 | 7 |
| 1 | 5 | .72 | 2 | 8 |
| 2 | 1 | .97 | 12 | 5 |
| 2 | 2 | .86 | 3 | 7 |
| 2 | 3 | .70 | 2 | 3 |
| 2 | 4 | .66 | 2 | 4 |
| 3 | 1 | .96 | 10 | 6 |
| 3 | 2 | .89 | 6 | 8 |
| 3 | 3 | .72 | 4 | 2 |
| 3 | 4 | .71 | 3 | 4 |
| 3 | 5 | .67 | 2 | 4 |

## Verificação de nominalidade (§4.3) — PASSOU

Nos três subsistemas, r e c são (fracamente) decrescentes no índice publicado, mas **w é não-monótono em todos** (S1: 9,6,4,7,8; S2: 5,7,3,4; S3: 6,8,2,4,4). Logo, nenhuma ordem total dos tipos é simultaneamente consistente com fiabilidade, custo e peso — o requisito moderado congelado no protocolo. Registo honesto: a defesa da nominalidade assenta no peso (r e c isolados estão alinhados com o índice). Tipo dominado: **S2 tipo 4** é dominado por S2 tipo 3 (r .66 < .70, c 2 = 2, w 4 > 3) — admissível na formulação moderada; coerentemente, **nunca aparece na frente exata**.

## Enumeração da frente exata (verificação prévia, Python; a reproduzir em MATLAB com `enumerate_morap_nm.m`)

- |Ω| = 5·4·5·7³ = **34 300** ✓
- **|X⋆| = 578** decisões Pareto-ótimas (dominância estrita, Def. 2.2)
- **Vetores objetivo todos distintos** (|ℱ⋆| = 578) → matching por identidade sem ambiguidade; a lista do algoritmo (uma entrada por vetor objetivo) pode em princípio atingir recall 100%
- Gamas na frente (convenção F₁ = 1−R): (1−R) ∈ [2.99·10⁻⁹, 0.6623], C ∈ [6, 217], W ∈ [9, 147]
- Utilização de tipos na frente: S1 {13, 178, 227, 66, 94}; S2 {106, 184, 288, **0**}; S3 {121, 51, 131, 71, 204} — todos os tipos não-dominados aparecem
- Ficheiro: `morap_nm_exact_front_decisions.csv` (578 × 9: z₁,n₁,z₂,n₂,z₃,n₃, 1−R, C, W — convenções congeladas)
- Nota comparativa: a formulação de Cao (com mistura) tem 6112 pontos Pareto-ótimos; 578 é a frente do objeto *diferente* que é o MORAP-NM — nunca confundir os dois nem reutilizar a frente publicada

## Ficheiros entregues

`morap_nm_data.m` (dados + proveniência + verificação de nominalidade em comentário; lookup por rótulo para B3b), `driver_morap_nm.m` (ProblemData na ordem intercalada (z₁,n₁,z₂,n₂,z₃,n₃); F₁ = 1−R; argumento opcional `label_order` para o teste B3b; objetivos por rótulo), `enumerate_morap_nm.m` (enumeração MATLAB independente devolvendo [Xdec, Fdec, Fobj], valores de referência 578/578 no cabeçalho).

## Próximo passo (piloto, Protocolo §8)

1. Correr `enumerate_morap_nm.m` em MATLAB e confirmar 578/578 contra o CSV da verificação Python; 2. correr `driver_morap_nm` com as três variantes (`poll_variant` = 'fixed' com dnr_mode=0 / 'cc_dnr' / 'full') e critérios de aceitação do piloto; 3. B3a (conformidade, traços idênticos) e B3b (sensibilidade à indexação via `label_order`); 4. métricas contra a frente exata com `front_matching.m` + `metrics_objective.m`.
