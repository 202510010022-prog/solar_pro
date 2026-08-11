# Validação regional Brasil: Solar Pro x PVGIS oficial

## Objetivo

Validar o cálculo de geração mensal/anual do Solar Pro contra dados oficiais do PVGIS/JRC em quatro regiões brasileiras, usando uma potência normalizada de 1 kWp.

Esta validação não calibra fórmulas, PR, perdas ou thresholds. Diferenças encontradas são registradas como evidência para análise futura.

## Metodologia

- Fonte PVGIS: Joint Research Centre / European Commission, API PVGIS 5.3.
- Ferramenta: `PVcalc`.
- Captura direta no endpoint oficial JRC, sem passar pela Edge Function Solar Pro.
- Data de captura: `2026-08-11T19:06:39Z`.
- CEPs conferidos no ViaCEP na mesma captura.
- Coordenadas: referência urbana central da cidade, não coordenada de telhado específico.
- Fixture congelado: `mobile_app/test/fixtures/pvgis_brazil_cases.json`.
- Script manual de captura: `tools/fetch_pvgis_brazil_cases.py`.

Premissas PVGIS:

- `peakpower = 1.0 kWp`
- `loss = 14%`
- `pvtechchoice = crystSi`
- `mountingplace = free`
- `optimalangles = 1`
- `radiation database = auto`

Premissas Solar Pro:

- `performanceRatio = 0.80`
- `modulePower = 1000 W`
- consumo sintético: `50 kWh/mês`
- geração extra: `0%`
- potência instalada normalizada resultante: `1.0 kWp`
- cálculo executado pelo `SizingService` real do app

Observação metodológica: o PR Solar Pro e o `loss=14%` do PVGIS pertencem a modelos diferentes. A diferença observada entre gerações é parte do que está sendo medido.

## Tabela-resumo

| Região | Cidade | CEP | DB | Inclinação | Azimute | HSP anual | Solar Pro kWh/ano | PVGIS kWh/ano | Dif. % | Status |
|---|---|---:|---|---:|---:|---:|---:|---:|---:|---|
| Nordeste | Salvador/BA | 40010000 | PVGIS-SARAH3 | 11° | 1° | 5,69 | 1661,4 | 1587,1 | -4,47% | OK |
| Sudeste | São Paulo/SP | 01001000 | PVGIS-SARAH3 | 25° | 13° | 4,86 | 1419,1 | 1348,9 | -4,94% | OK |
| Sul | Curitiba/PR | 80010000 | PVGIS-SARAH3 | 26° | 1° | 4,64 | 1355,6 | 1303,7 | -3,83% | OK |
| Norte | Manaus/AM | 69005070 | PVGIS-SARAH3 | 2° | 43° | 4,90 | 1429,6 | 1313,5 | -8,13% | OK |

Status:

- `OK`: diferença absoluta menor ou igual a 15%.
- `Revisar`: diferença absoluta maior que 15%.

## Casos

### Salvador / BA

- Região: Nordeste
- CEP: `40010000`
- ViaCEP: Avenida da França, Comércio, Salvador/BA
- Coordenadas: `-12.9714`, `-38.5014`
- PVGIS DB: `PVGIS-SARAH3`
- PVGIS slope: `11°`
- PVGIS aspect: `-179°`
- Azimute geográfico Solar Pro: `1°` (N)
- Período da base: `2005-2023`
- Elevação: `68 m`
- Irradiação anual no plano: `2077,23 kWh/m²/ano`
- Variabilidade anual: `45,97 kWh`
- HSP médio anual ponderado: `5,69 h/dia`
- Solar Pro anual: `1661,4 kWh`
- PVGIS E_y: `1587,1 kWh`
- Σ PVGIS E_m: `1587,1 kWh`
- E_y - ΣE_m: `0,000 kWh`
- Diferença anual: `-4,47%`
- Status: `OK`
- Maior diferença mensal: Mar, Solar Pro `156,2 kWh`, PVGIS `147,4 kWh`, diferença `-5,64%`

| Mês | HSP h/dia | Solar Pro kWh | PVGIS kWh | Diferença % |
|---|---:|---:|---:|---:|
| Jan | 6,44 | 159,7 | 151,3 | -5,29% |
| Fev | 6,56 | 146,9 | 138,8 | -5,52% |
| Mar | 6,30 | 156,2 | 147,4 | -5,64% |
| Abr | 5,40 | 129,6 | 122,7 | -5,33% |
| Mai | 4,55 | 112,8 | 108,0 | -4,28% |
| Jun | 4,53 | 108,7 | 105,3 | -3,18% |
| Jul | 4,85 | 120,3 | 116,8 | -2,88% |
| Ago | 5,49 | 136,2 | 132,0 | -3,04% |
| Set | 5,93 | 142,3 | 137,2 | -3,59% |
| Out | 6,17 | 153,0 | 146,5 | -4,25% |
| Nov | 5,95 | 142,8 | 135,9 | -4,82% |
| Dez | 6,16 | 152,8 | 145,2 | -4,98% |

### São Paulo / SP

- Região: Sudeste
- CEP: `01001000`
- ViaCEP: Praça da Sé, Sé, São Paulo/SP
- Coordenadas: `-23.5505`, `-46.6333`
- PVGIS DB: `PVGIS-SARAH3`
- PVGIS slope: `25°`
- PVGIS aspect: `-167°`
- Azimute geográfico Solar Pro: `13°` (N)
- Período da base: `2005-2023`
- Elevação: `778 m`
- Irradiação anual no plano: `1774,09 kWh/m²/ano`
- Variabilidade anual: `58,43 kWh`
- HSP médio anual ponderado: `4,86 h/dia`
- Solar Pro anual: `1419,1 kWh`
- PVGIS E_y: `1348,9 kWh`
- Σ PVGIS E_m: `1348,9 kWh`
- E_y - ΣE_m: `0,000 kWh`
- Diferença anual: `-4,94%`
- Status: `OK`
- Maior diferença mensal: Jan, Solar Pro `122,3 kWh`, PVGIS `114,7 kWh`, diferença `-6,22%`

| Mês | HSP h/dia | Solar Pro kWh | PVGIS kWh | Diferença % |
|---|---:|---:|---:|---:|
| Jan | 4,93 | 122,3 | 114,7 | -6,22% |
| Fev | 5,45 | 122,1 | 114,5 | -6,18% |
| Mar | 5,28 | 130,9 | 123,4 | -5,77% |
| Abr | 5,00 | 120,0 | 114,5 | -4,60% |
| Mai | 4,38 | 108,6 | 104,8 | -3,57% |
| Jun | 4,23 | 101,5 | 98,7 | -2,81% |
| Jul | 4,65 | 115,3 | 111,7 | -3,13% |
| Ago | 4,86 | 120,5 | 115,5 | -4,20% |
| Set | 4,78 | 114,7 | 108,9 | -5,11% |
| Out | 4,67 | 115,8 | 109,0 | -5,87% |
| Nov | 4,98 | 119,5 | 113,2 | -5,27% |
| Dez | 5,15 | 127,7 | 120,2 | -5,91% |

### Curitiba / PR

- Região: Sul
- CEP: `80010000`
- ViaCEP: Rua José Loureiro, Centro, Curitiba/PR
- Coordenadas: `-25.4284`, `-49.2733`
- PVGIS DB: `PVGIS-SARAH3`
- PVGIS slope: `26°`
- PVGIS aspect: `-179°`
- Azimute geográfico Solar Pro: `1°` (N)
- Período da base: `2005-2023`
- Elevação: `919 m`
- Irradiação anual no plano: `1694,77 kWh/m²/ano`
- Variabilidade anual: `58,05 kWh`
- HSP médio anual ponderado: `4,64 h/dia`
- Solar Pro anual: `1355,6 kWh`
- PVGIS E_y: `1303,7 kWh`
- Σ PVGIS E_m: `1303,7 kWh`
- E_y - ΣE_m: `-0,010 kWh`
- Diferença anual: `-3,83%`
- Status: `OK`
- Maior diferença mensal: Fev, Solar Pro `119,8 kWh`, PVGIS `113,2 kWh`, diferença `-5,54%`

| Mês | HSP h/dia | Solar Pro kWh | PVGIS kWh | Diferença % |
|---|---:|---:|---:|---:|
| Jan | 5,06 | 125,5 | 118,5 | -5,53% |
| Fev | 5,35 | 119,8 | 113,2 | -5,54% |
| Mar | 5,04 | 125,0 | 118,7 | -5,03% |
| Abr | 4,67 | 112,1 | 107,8 | -3,80% |
| Mai | 4,04 | 100,2 | 98,0 | -2,14% |
| Jun | 3,82 | 91,7 | 90,4 | -1,44% |
| Jul | 4,28 | 106,1 | 104,7 | -1,39% |
| Ago | 4,55 | 112,8 | 110,3 | -2,29% |
| Set | 4,41 | 105,8 | 102,2 | -3,49% |
| Out | 4,33 | 107,4 | 102,6 | -4,43% |
| Nov | 5,05 | 121,2 | 116,1 | -4,24% |
| Dez | 5,16 | 128,0 | 121,3 | -5,23% |

### Manaus / AM

- Região: Norte
- CEP: `69005070`
- ViaCEP: Avenida Floriano Peixoto, Centro, Manaus/AM
- Coordenadas: `-3.1190`, `-60.0217`
- PVGIS DB: `PVGIS-SARAH3`
- PVGIS slope: `2°`
- PVGIS aspect: `-137°`
- Azimute geográfico Solar Pro: `43°` (NE)
- Período da base: `2005-2023`
- Elevação: `49 m`
- Irradiação anual no plano: `1787,21 kWh/m²/ano`
- Variabilidade anual: `30,45 kWh`
- HSP médio anual ponderado: `4,90 h/dia`
- Solar Pro anual: `1429,6 kWh`
- PVGIS E_y: `1313,5 kWh`
- Σ PVGIS E_m: `1313,5 kWh`
- E_y - ΣE_m: `-0,010 kWh`
- Diferença anual: `-8,13%`
- Status: `OK`
- Maior diferença mensal: Out, Solar Pro `135,7 kWh`, PVGIS `123,5 kWh`, diferença `-8,93%`

| Mês | HSP h/dia | Solar Pro kWh | PVGIS kWh | Diferença % |
|---|---:|---:|---:|---:|
| Jan | 4,51 | 111,8 | 103,1 | -7,79% |
| Fev | 4,51 | 101,0 | 93,2 | -7,71% |
| Mar | 4,33 | 107,4 | 98,8 | -7,98% |
| Abr | 4,39 | 105,4 | 97,0 | -7,93% |
| Mai | 4,32 | 107,1 | 98,9 | -7,68% |
| Jun | 4,90 | 117,6 | 108,8 | -7,44% |
| Jul | 5,33 | 132,2 | 122,1 | -7,61% |
| Ago | 5,71 | 141,6 | 129,8 | -8,30% |
| Set | 5,73 | 137,5 | 125,4 | -8,84% |
| Out | 5,47 | 135,7 | 123,5 | -8,93% |
| Nov | 5,02 | 120,5 | 109,9 | -8,76% |
| Dez | 4,51 | 111,8 | 102,7 | -8,17% |

## Conclusão

Nos quatro casos capturados, o PVGIS ficou abaixo do Solar Pro:

- PVGIS maior que Solar Pro: 0 casos
- PVGIS menor que Solar Pro: 4 casos
- Status OK: 4 casos
- Status Revisar: 0 casos

A maior diferença anual foi Manaus/AM, com `-8,13%`, ainda dentro da faixa de revisão Solar Pro de `±15%`.

Esta validação não indica necessidade imediata de recalibrar o PR. Se futuras capturas ou dados reais mostrarem tendência sistemática fora da faixa, a calibração deve ser tratada em tarefa separada.

Hipóteses técnicas possíveis para diferenças, sem conclusão causal neste item:

- PR simplificado do Solar Pro;
- modelagem de perdas do PVGIS;
- temperatura;
- efeitos espectrais;
- AOI;
- arredondamentos;
- diferenças entre modelos simplificados e PVGIS.

## Snapshot

O fixture é congelado porque o PVGIS pode atualizar bases e dados no futuro. Atualizar o snapshot deve ser uma ação explícita, executando o script manual e revisando o relatório novamente.
