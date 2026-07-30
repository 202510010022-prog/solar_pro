# Solar Pro - Tarefas Comerciais

## Semana 1 - Produto e oferta

### Identidade

- [ ] Confirmar nome final do produto
- [ ] Confirmar slogan
- [ ] Separar logo final para app, site e proposta
- [ ] Definir cores finais da marca

### Publico inicial

- [ ] Escolher foco principal do beta
- [ ] Listar 5 empresas ou usuarios para convidar
- [ ] Definir perfil do comprador ideal

### Planos

- [ ] Validar Plano Starter
- [ ] Validar Plano Equipe
- [ ] Validar Plano Pro
- [ ] Confirmar limites de usuarios
- [ ] Confirmar limites de projetos
- [ ] Confirmar se havera teste gratis

### Precos

- [ ] Validar preco Starter
- [ ] Validar preco Equipe
- [ ] Validar preco Pro
- [ ] Definir desconto para pagamento anual
- [ ] Definir preco especial para empresa junior

### Comercial

- [ ] Criar mensagem curta para WhatsApp
- [ ] Criar apresentacao simples de 1 pagina
- [ ] Criar roteiro de demonstracao
- [ ] Criar lista de perguntas para feedback

## Semana 2 - Assinatura no Supabase

- [x] Criar tabela `plans`
- [x] Criar tabela `subscriptions`
- [x] Adicionar campos comerciais em `companies`
- [x] Criar status de assinatura
- [x] Criar regras de limite por plano
- [x] Preparar usuarios de beta

## Semana 3 - Controle no app

- [x] Consultar plano ao abrir app
- [x] Mostrar plano na aba Mais
- [x] Bloquear criacao quando assinatura estiver vencida
- [x] Bloquear recursos por permissao/plano
- [x] Criar mensagens amigaveis de limite

## Semana 4 - Beta manual

- [ ] Cadastrar empresas beta
- [ ] Criar usuarios reais
- [x] Preparar controle de cobranca manual por Pix
- [x] Preparar coleta de feedback semanal
- [ ] Cobrar manualmente por Pix
- [ ] Coletar feedback semanal
- [ ] Corrigir bugs encontrados

## Semana 5 - Central operacional do beta

- [x] Criar painel interno de feedbacks
- [x] Permitir atualizar status dos feedbacks
- [x] Criar painel de cobrancas Pix manuais
- [x] Permitir marcar cobranca como paga
- [x] Criar mensagem padrao de convite beta
- [x] Criar convite seguro de usuarios via Edge Function
- [ ] Criar cadastro de cobranca Pix direto pelo app
- [x] Conectar convite seguro na tela de usuarios da equipe
- [x] Listar usuarios da empresa no app
- [x] Ativar/desativar usuarios da equipe

## Semana 6 - Cobranca Pix no app

- [x] Criar Edge Function segura para cobrancas
- [x] Criar cobranca Pix pelo app
- [x] Cancelar cobranca pelo app
- [x] Marcar cobranca como paga pelo app
- [x] Ativar assinatura ao confirmar pagamento
- [x] Atualizar periodo da assinatura ao confirmar pagamento
- [x] Mostrar aviso de cobranca pendente na tela inicial
- [x] Automatizar cobrancas vencidas

## Semana 7 - Alertas comerciais

- [x] Sincronizar cobrancas vencidas ao abrir dashboard
- [x] Mostrar alerta de cobranca pendente no dashboard
- [x] Mostrar alerta de cobranca atrasada no dashboard
- [x] Mostrar resumo de cobrancas na aba Mais
- [x] Criar recibo simples de pagamento
- [x] Criar relatorio financeiro mensal

## Semana 8 - Fechamento financeiro manual

- [x] Mostrar total recebido no mes
- [x] Mostrar total pendente
- [x] Mostrar total atrasado
- [x] Mostrar quantidade de pagamentos pagos no mes
- [x] Criar recibo em texto para pagamento confirmado
- [x] Permitir copiar recibo
- [ ] Gerar recibo em PDF
- [ ] Exportar financeiro mensal em CSV

## Limpeza do app do cliente

- [x] Remover Central do beta da navegacao do app
- [x] Criar tela de Mensagens para avisos e cobrancas
- [x] Criar tabela `app_messages` no Supabase
- [x] Gerar mensagens automaticas nas cobrancas Pix
- [x] Separar painel administrativo em app/web proprio

## Painel administrativo separado

- [x] Criar projeto `admin_app`
- [x] Criar Edge Function `admin-company`
- [x] Listar empresas da plataforma
- [x] Cadastrar empresa com usuario master
- [x] Editar plano, status e validade da assinatura
- [x] Proteger acesso por permissao `owner`/`admin`
- [x] Criar modulo de cobrancas Pix por empresa
- [x] Enviar mensagem ao app quando criar cobranca
- [x] Ativar assinatura ao confirmar pagamento no admin
- [x] Criar modulo de feedbacks e chamados
- [x] Alterar status de chamados pelo admin
- [x] Criar modulo de mensagens/comunicados
- [x] Enviar comunicado para uma empresa especifica
- [x] Enviar comunicado para todas as empresas ativas
- [x] Listar mensagens enviadas no admin
- [x] Criar modulo de dependentes/usuarios por empresa
- [x] Criar usuarios pelo painel admin
- [x] Ativar/desativar usuarios pelo painel admin
- [x] Separar visualmente usuarios por empresa no painel admin
- [x] Mostrar vencimento de teste/assinatura na lista de empresas
- [x] Criar modulo de relatorios comerciais
- [x] Mostrar receita recebida, pendente e atrasada
- [x] Mostrar conversao teste para ativo
- [x] Mostrar usuarios por plano
- [x] Mostrar ranking de empresas por uso
- [x] Organizar painel admin em secoes clicaveis
