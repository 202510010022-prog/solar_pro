# Solar Pro - Semana 6

## Objetivo

Transformar a cobranca Pix manual em uma rotina operacional dentro do app, sem abrir o SQL Editor.

## Entregas implementadas

- Edge Function `manage-payment` para gerenciar cobrancas com seguranca.
- Criacao de cobranca Pix pelo app.
- Cancelamento de cobranca pendente/atrasada.
- Confirmacao de pagamento pelo app.
- Ao marcar como pago:
  - pagamento vira `paid`;
  - empresa vira assinatura `active`;
  - `subscription_ends_at` e periodo da assinatura sao atualizados;
  - provider fica `manual`.
- Aba Pix da `Central do beta` atualizada com botoes operacionais.

## Fluxo comercial atual

1. Diretor/admin abre `Mais > Central do beta > Pix`.
2. Clica em `Nova cobrança Pix`.
3. Informa valor, vencimento, referencia Pix e observacao.
4. Quando receber o Pix, clica em `Marcar como pago`.
5. Escolhe periodo liberado: 1, 3, 6 ou 12 meses.
6. O Supabase atualiza cobranca e assinatura.

## Seguranca

O app nao atualiza diretamente dados sensiveis de assinatura. A funcao `manage-payment` valida:

- token JWT;
- perfil ativo;
- permissao `diretor`, `admin` ou `owner`;
- empresa do usuario;
- cobranca pertencente a mesma empresa.

## Arquivos principais

- `supabase/functions/manage-payment/index.ts`
- `mobile_app/lib/services/solarpro_repository.dart`
- `mobile_app/lib/screens/beta_admin_page.dart`
- `mobile_app/lib/models/manual_payment.dart`

## Proximos passos

- Mostrar aviso de cobranca pendente na tela inicial ou na aba Mais.
- Automatizar status `overdue` quando passar do vencimento.
- Criar integracao real com gateway de pagamento quando sair do beta manual.
- Criar recibo simples para pagamento confirmado.
