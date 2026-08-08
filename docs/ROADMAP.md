# Roadmap Solar Pro

## Acompanhamento pos-venda: geracao real vs estimada (planejado)

Objetivo: permitir que a equipe registre dados reais informados pela concessionaria de energia (geracao, consumo, saldo) por cliente/projeto, para comparar com a estimativa feita no momento da venda (dados PVGIS ja salvos no projeto). Cria motivo de recontato anual com o cliente e pode sinalizar problemas no sistema (geracao muito abaixo do esperado).

### Decisoes ja tomadas

- Entrada de dados: MANUAL por enquanto (equipe digita os numeros vistos no relatorio/fatura da concessionaria).
- Frequencia: flexivel - permitir registro mensal E anual, nao so anual.
- Visao de futuro (nao agora): importacao automatica via OCR de foto da fatura/relatorio, ou integracao direta com concessionaria se disponivel.

### Pendente de mapeamento tecnico antes de implementar

- Nova tabela para armazenar esses registros (ex: `energy_readings`), vinculada a `client_id` e/ou `project_id`, com `period` (mes/ano), `generated_kwh`, `consumed_kwh`, `saldo_kwh`.
- RLS: isolar por empresa, seguindo o mesmo padrao de seguranca ja usado em todo o projeto.
- UI: tela/secao para registrar e visualizar esses dados por cliente, comparando com a estimativa salva no projeto (`monthly_generations` ja existente).
- Possivel grafico de comparacao real vs estimado.

Status: PLANEJADO, aguardando decisao de quando implementar.
