# Solar Pro - limpeza do app do cliente

Data: 04/06/2026

## Decisão de produto

O app mobile deve ser a experiência principal do cliente e da equipe operacional. As telas internas de beta, cobrança e operação administrativa não devem aparecer como uma central dentro do app do cliente.

## O que ficou no app

- Dashboard
- CRM
- Projetos
- Dimensionamento
- Mais
- Mensagens
- Feedback
- Usuários da equipe para perfis com permissão administrativa
- Assinatura e status de sincronização

## O que saiu da navegação

- Central do beta
- Gestão manual de Pix dentro do app do cliente
- Relatórios administrativos de beta

Os arquivos administrativos foram mantidos no código por enquanto para reaproveitamento futuro em um painel separado.

## Mensagens

Foi criada a entidade `app_messages` no Supabase para comunicação dentro do app.

Uso previsto:

- Avisos de cobrança
- Confirmação de pagamento
- Alertas operacionais
- Comunicados da plataforma

As mensagens podem ser marcadas como lidas ou arquivadas pelo usuário.

## Próxima etapa recomendada

Criar um painel administrativo separado para:

- Cadastro de empresas
- Usuário master
- Dependentes da empresa
- Cobrança Pix
- Controle de assinatura
- Feedbacks do beta
