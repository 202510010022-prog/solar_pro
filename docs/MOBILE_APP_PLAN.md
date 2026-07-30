# Solar Pro Mobile Plan

## Objetivo

Criar um app iOS/Android para apoio em visitas e operacao de campo, conectado
ao mesmo Supabase do Solar Pro Desktop.

## Stack recomendada

- Flutter
- Supabase Auth
- Supabase Database
- Cache local simples na primeira fase
- SQLite/Drift em fase posterior para fila robusta offline-first

## Escopo do mobile

- Login da equipe
- Dashboard de projetos
- Cadastro e consulta de clientes
- Consulta de projetos
- Atualizacao de status
- Dimensionamento rapido

## Nao entra no mobile

- PDF de proposta
- Importacao de fatura
- Anexos pesados
- Configuracoes administrativas complexas

## Fases

1. App base com login e leitura do Supabase. Concluido na base inicial.
2. Cadastro de clientes e atualizacao de status. Concluido na base inicial.
3. Criacao de projeto/dimensionamento salvo no Supabase. Concluido nesta fase.
4. Offline-first robusto com fila de sincronizacao.
5. Build iOS via macOS/Xcode e TestFlight.
