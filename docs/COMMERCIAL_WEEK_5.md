# Solar Pro - Semana 5

## Objetivo

Criar uma primeira central operacional para administrar o beta sem depender apenas do SQL Editor.

## Entregas implementadas

- Tela `Central do beta` disponivel para usuarios com permissao de diretor/admin/owner.
- Tela `Usuarios da equipe` para listar acessos da empresa.
- Formulario de convite conectado a Edge Function `invite-user`.
- Acao para ativar/desativar perfil da equipe.
- Aba de feedbacks recebidos pelo app.
- Atualizacao de status dos feedbacks:
  - Aberto
  - Em analise
  - Resolvido
  - Arquivado
- Aba de cobrancas Pix manuais.
- Acao para marcar cobranca manual como paga.
- Aba de convites com mensagem pronta para usuario beta.
- Edge Function `invite-user` para criar usuarios com seguranca.

## Arquitetura

- Modelos:
  - `mobile_app/lib/models/beta_feedback.dart`
  - `mobile_app/lib/models/manual_payment.dart`
  - `mobile_app/lib/models/team_invite_result.dart`
- Servico:
  - `mobile_app/lib/services/solarpro_repository.dart`
- Interface:
  - `mobile_app/lib/screens/beta_admin_page.dart`
  - `mobile_app/lib/screens/team_users_page.dart`
  - `mobile_app/lib/screens/more_page.dart`

## Decisao de seguranca

A criacao automatica de usuario foi colocada em uma Edge Function. O app nao deve carregar chave de service role. O fluxo correto e:

- validar permissao de diretor/admin;
- criar usuario no Auth pelo servidor;
- criar perfil vinculado a empresa;
- retornar uma senha temporaria ou enviar convite por e-mail.

Funcao criada:

- `supabase/functions/invite-user/index.ts`
- Documentacao: `docs/EDGE_INVITE_USER.md`

## Proximos passos

- Melhorar a tela `Usuarios da equipe` com edicao de cargo/permissao.
- Criar painel web interno para administracao do produto.
- Criar tela para registrar cobranca Pix direto pelo app.
- Criar relatorio de feedbacks por area e prioridade.
- Automatizar aviso de trial vencendo.
