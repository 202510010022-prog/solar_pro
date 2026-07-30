# Solar Pro - Semana 4

## Objetivo

Colocar o Solar Pro em beta manual com empresas reais, mantendo controle simples de acesso, pagamento por Pix, feedback semanal e correcao rapida de bugs.

## O que ficou pronto no produto

- Tabela `manual_payments` para acompanhar cobrancas manuais por Pix.
- Tabela `beta_feedback` para receber feedback pelo app.
- Politicas RLS para manter pagamentos e feedback isolados por empresa.
- Botao `Enviar feedback` na aba Mais do app mobile.
- Checklist operacional para cadastrar beta testers sem depender de automacao de pagamento.

## Fluxo recomendado do beta

1. Escolha 3 a 5 empresas pequenas ou empresas junior.
2. Cadastre a empresa no Supabase com `subscription_status = 'trial'`.
3. Crie 1 usuario diretor e, se necessario, usuarios assessores.
4. Envie APK ou link web.
5. Faca uma demonstracao de 10 minutos.
6. Acompanhe o uso por 7 dias.
7. Peça feedback dentro do app.
8. Corrija bugs criticos antes de chamar novos usuarios.
9. Se o usuario quiser continuar, registre cobranca Pix em `manual_payments`.
10. Depois do pagamento, mude `subscription_status` para `active`.

## Status de pagamento manual

- `pending`: cobranca aberta.
- `paid`: pagamento confirmado.
- `overdue`: pagamento atrasado.
- `canceled`: cobranca cancelada.

## Status de feedback

- `open`: feedback novo.
- `reviewing`: em analise.
- `resolved`: resolvido.
- `archived`: guardado sem acao imediata.

## Rotina semanal

### Segunda

- Ver empresas com teste vencendo.
- Ver feedbacks abertos.
- Separar 3 bugs ou melhorias prioritarias.

### Quarta

- Corrigir e testar melhorias pequenas.
- Enviar nova build se necessario.

### Sexta

- Conversar com os usuarios beta.
- Perguntar se pagariam pelo produto.
- Atualizar status de pagamento e assinatura.

## Perguntas para o beta

- Voce conseguiu criar cliente e projeto sem ajuda?
- O dimensionamento ficou claro?
- O que ficou confuso?
- O que faltaria para usar em uma empresa real?
- Voce pagaria mensalidade por isso hoje?
- Qual valor faria sentido?
- O app mobile resolve sua rotina ou precisa web/desktop tambem?

## Proximo passo apos a Semana 4

Entrar na Semana 5 com base no feedback real:

- Tela administrativa simples para empresas e assinaturas.
- Painel interno de feedbacks.
- Fluxo de convite de usuarios.
- Primeira versao de cobranca automatizada.
