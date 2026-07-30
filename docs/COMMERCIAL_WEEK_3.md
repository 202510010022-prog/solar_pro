# Solar Pro - Semana 3

## Objetivo

Conectar as regras comerciais do Supabase ao aplicativo, para que o plano da empresa deixe de ser apenas cadastro no banco e passe a controlar a experiencia real do usuario.

## Entregas implementadas

- Consulta do plano ao abrir o aplicativo.
- Cache local do plano para manter o comportamento offline-first.
- Exibicao do plano, status, limites e recursos na aba Mais.
- Exibicao de plano e status no menu lateral.
- Bloqueio de criacao de projeto quando a assinatura esta vencida, cancelada ou bloqueada.
- Bloqueio por limite mensal de projetos do plano.
- Mensagens amigaveis para assinatura irregular e limite mensal atingido.

## Regras atuais

- `trial`: permitido enquanto a data de teste estiver valida.
- `active`: permitido.
- `past_due`, `canceled` e `blocked`: bloqueiam novos projetos.
- `max_projects_per_month = null`: projetos ilimitados.
- `max_projects_per_month` com valor numerico: limita projetos criados no mes atual.

## Onde a regra vive

- Modelo: `mobile_app/lib/models/app_subscription.dart`
- Servico: `mobile_app/lib/services/solarpro_repository.dart`
- Tela Mais: `mobile_app/lib/screens/more_page.dart`
- Dimensionamento: `mobile_app/lib/screens/sizing_page.dart`
- Menu lateral: `mobile_app/lib/screens/home_page.dart`

## Proximos refinamentos

- Criar uma tela administrativa para alterar plano/status sem acessar o SQL Editor.
- Adicionar aviso visual quando faltar poucos dias para acabar o teste.
- Enviar notificacao interna quando uma empresa atingir 80% do limite mensal.
- Registrar tentativas bloqueadas em uma tabela de auditoria.
