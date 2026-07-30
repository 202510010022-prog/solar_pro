# Solar Pro - Semana 7

## Objetivo

Adicionar alertas comerciais e automatizar a transicao de cobrancas vencidas para reduzir acompanhamento manual.

## Entregas implementadas

- Acao `sync_overdue` na Edge Function `manage-payment`.
- Dashboard sincroniza cobrancas vencidas ao abrir/atualizar.
- Dashboard exibe alerta quando ha cobranca pendente ou atrasada.
- Aba Mais exibe status resumido das cobrancas para diretor/admin/owner.
- Repositorio ganhou carregamento de cobrancas abertas.

## Comportamento

- Cobrancas `pending` com `due_date` anterior ao dia atual viram `overdue`.
- Cobrancas `pending` e `overdue` aparecem nos alertas.
- O dashboard destaca cobrancas atrasadas antes das pendentes.

## Arquivos principais

- `supabase/functions/manage-payment/index.ts`
- `mobile_app/lib/services/solarpro_repository.dart`
- `mobile_app/lib/screens/dashboard_page.dart`
- `mobile_app/lib/screens/more_page.dart`

## Proximos passos

- Criar recibo simples para pagamento confirmado.
- Criar relatorio financeiro mensal.
- Criar notificacao local/push para vencimento proximo.
- Preparar fluxo com gateway real de pagamento.
