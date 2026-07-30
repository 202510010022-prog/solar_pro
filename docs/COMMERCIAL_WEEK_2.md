# Solar Pro - Semana 2 Assinaturas

## Objetivo da semana

Criar a base tecnica de assinatura no Supabase para permitir planos comerciais, status de pagamento, periodo de teste e limites por empresa.

## Entregas realizadas

- Criada tabela `plans`
- Criada tabela `subscriptions`
- Adicionados campos comerciais em `companies`
- Criadas funcoes auxiliares de assinatura
- Criada view `company_billing_overview`
- Criadas politicas RLS para planos e assinaturas
- Criados indices para consultas comerciais
- Atualizado `supabase/schema.sql`
- Criada migration `20260604_commercial_subscriptions.sql`
- Atualizado seed de usuarios de teste para plano beta `equipe`
- Migration aplicada no Supabase remoto

## Planos cadastrados

### Starter

- Preco mensal: R$ 39,90
- Preco anual: R$ 399,00
- Usuarios: 1
- Projetos por mes: 30
- Financeiro: nao
- Relatorios: nao

### Equipe

- Preco mensal: R$ 99,90
- Preco anual: R$ 999,00
- Usuarios: 5
- Projetos por mes: ilimitado
- Financeiro: sim
- Relatorios: nao

### Pro

- Preco mensal: R$ 199,90
- Preco anual: R$ 1.999,00
- Usuarios: 15
- Projetos por mes: ilimitado
- Financeiro: sim
- Relatorios: sim

## Status de assinatura

Status previstos para uso comercial:

- `trial`: periodo de teste
- `active`: assinatura ativa
- `past_due`: pagamento atrasado
- `canceled`: assinatura cancelada
- `blocked`: acesso bloqueado

## Campos adicionados em companies

- `plan_slug`
- `subscription_status`
- `trial_ends_at`
- `subscription_ends_at`
- `billing_email`
- `billing_provider`
- `billing_customer_id`
- `billing_notes`

## Funcoes criadas

- `current_company_plan_slug()`
- `current_company_subscription_status()`
- `current_company_subscription_active()`
- `current_company_monthly_project_count()`

## View criada

`company_billing_overview`

Uso esperado:

- Mostrar assinatura na aba Mais
- Consultar limites do plano
- Exibir status comercial da empresa
- Preparar bloqueios da Semana 3

## Estado do Supabase remoto

Validado no Supabase remoto:

- Planos `starter`, `equipe` e `pro` cadastrados
- Empresas de teste ajustadas para plano `equipe`
- Assinaturas de teste sincronizadas como `trial`
- View de billing retornando dados comerciais

## Proximo passo

Semana 3:

- Criar modelo de assinatura no app
- Carregar dados de plano ao fazer login
- Mostrar assinatura na aba Mais
- Bloquear criacao de projetos quando assinatura estiver vencida
- Aplicar limite mensal do plano Starter
- Mostrar mensagens amigaveis de limite/plano
