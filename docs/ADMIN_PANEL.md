# Solar Pro Admin

Painel administrativo separado do app do cliente.

## Objetivo

Centralizar operações da plataforma:

- Cadastrar empresas
- Criar usuário master da empresa
- Criar dependentes/usuários por empresa
- Ativar ou desativar usuários
- Consultar empresas cadastradas
- Ver usuários, projetos e valores pendentes por empresa
- Acompanhar vencimento do teste ou assinatura por empresa
- Alterar plano, status e validade da assinatura
- Criar, confirmar e cancelar cobranças Pix por empresa
- Acompanhar feedbacks/chamados enviados pelo app
- Alterar status dos chamados
- Enviar comunicados para uma empresa especifica
- Enviar comunicados para todas as empresas ativas
- Visualizar relatórios comerciais da plataforma
- Acompanhar receita, inadimplência, conversão e uso por empresa

## Empresas

A aba Empresas mostra cada empresa com plano, status, vencimento, usuários,
projetos, pendências e ação de edição.

O vencimento usa a validade da assinatura quando existir. Quando a empresa ainda
está em teste, usa o fim do período de teste. O painel destaca empresas vencidas
ou perto do vencimento.

## Empresas e usuários

A aba Empresas e usuários é uma central de gestão por empresa.

Fluxo:

- Clique em uma empresa na lista lateral.
- Veja os dados comerciais da empresa selecionada.
- Edite nome, documento, e-mail de cobrança, plano, status e vencimento.
- Veja apenas os usuários vinculados à empresa.
- Crie novos usuários já associados à empresa selecionada.
- Edite nome, e-mail, matrícula, cargo, permissão, status e senha dos usuários.
- Ative ou desative dependentes da empresa selecionada.

## Navegação

O painel admin está dividido em seções clicáveis:

- Visão geral
- Empresas
- Empresas e usuários
- Cobranças
- Feedbacks
- Mensagens

## Acesso local

```bash
cd /home/kevinklecio96/solar_manager/admin_app
export PATH="/home/kevinklecio96/solar_manager/.tools/flutter/bin:$PATH"
flutter run -d chrome
```

Build servido localmente:

```text
http://127.0.0.1:8081/
```

## Segurança

O painel usa a Edge Function `admin-company`.

Regras:

- O navegador usa somente a chave pública do Supabase.
- A chave `service_role` fica apenas na Edge Function.
- Somente perfis com `permission` igual a `platform_admin` ou `admin` conseguem usar o painel.
- Usuários `owner` são Master da empresa cliente e acessam apenas o app da empresa.

## Privacidade por empresa

O app cliente filtra dados por `company_id` em clientes, projetos, mensagens,
cobranças e feedbacks.

O cache local do aplicativo também é separado por usuário autenticado. Assim,
quando alguém troca de conta no mesmo aparelho, os dados de uma empresa não
aparecem para outra enquanto a sincronização acontece.

No app, o Master da empresa pode gerenciar a equipe:

- Criar assessores
- Ver senha temporária gerada automaticamente
- Copiar a senha temporária
- Editar nome, e-mail, matrícula, permissão e senha
- Congelar ou reativar acesso
- Excluir assessores

O usuário Master da empresa é protegido contra exclusão/congelamento pelo app.

## Usuário plataforma

O usuário `kevinklecio96@gmail.com` foi configurado como:

```text
permission: platform_admin
role: Administrador da Plataforma
```

## Próximos módulos do painel

Os relatórios comerciais já estão no painel inicial do admin.
