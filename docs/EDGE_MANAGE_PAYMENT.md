# Edge Function - manage-payment

## Objetivo

Gerenciar cobrancas Pix manuais com seguranca e atualizar assinatura quando o pagamento for confirmado.

## URL

```text
https://uaomsrfbwthfgnayfdoa.supabase.co/functions/v1/manage-payment
```

## Acao: criar cobranca

```json
{
  "action": "create",
  "amount": 99.9,
  "due_date": "2026-06-11",
  "pix_reference": "chave ou txid",
  "notes": "Mensalidade beta"
}
```

## Acao: marcar como pago

```json
{
  "action": "mark_paid",
  "payment_id": 1,
  "period_months": 1
}
```

`period_months` aceita de 1 a 24, mas o app oferece 1, 3, 6 e 12 meses.

## Acao: cancelar

```json
{
  "action": "cancel",
  "payment_id": 1
}
```

## Acao: sincronizar vencidas

Marca como `overdue` as cobrancas pendentes com vencimento anterior a data atual.

```json
{
  "action": "sync_overdue"
}
```

## Seguranca

A funcao valida:

- token de acesso no header `Authorization`;
- usuario autenticado;
- perfil ativo;
- permissao `diretor`, `admin` ou `owner`;
- cobranca pertencente a empresa do usuario.

## Deploy

```bash
./.tools/supabase-cli/supabase functions deploy manage-payment --no-verify-jwt
```
