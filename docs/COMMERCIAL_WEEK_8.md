# Solar Pro - Semana 8

## Objetivo

Dar fechamento operacional para o financeiro manual: recibo simples e relatorio mensal dentro da Central do Beta.

## Entregas implementadas

- Relatorio financeiro mensal na aba Pix.
- Total recebido no mes.
- Total pendente.
- Total atrasado.
- Quantidade de pagamentos confirmados no mes.
- Recibo simples para cobrancas pagas.
- Botao para copiar recibo.

## Comportamento

- O relatorio usa as cobrancas carregadas em `manual_payments`.
- Pagamentos entram no total mensal quando `paid_at` esta no mes atual.
- Cobrancas `pending` entram como pendentes.
- Cobrancas `overdue` entram como atrasadas.
- Recibo fica disponivel apenas para cobrancas pagas.

## Arquivo principal

- `mobile_app/lib/screens/beta_admin_page.dart`

## Proximos passos

- Gerar recibo em PDF.
- Criar exportacao CSV do financeiro mensal.
- Criar tela com filtro por mes.
- Integrar gateway real de pagamento quando sair do beta manual.
