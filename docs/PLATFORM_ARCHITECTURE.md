# Solar Pro Platform Architecture

## Objetivo

Transformar o Solar Pro em uma plataforma comercial para operacao solar:

- CRM Solar
- Dimensionamento Fotovoltaico
- Simulacao Financeira
- Gestao de Projetos
- Propostas Comerciais
- Sincronizacao em Equipe

## Entidade central

`Project` e a entidade principal do sistema.

Cada projeto concentra:

- cliente vinculado
- dados de dimensionamento
- simulacao financeira
- producao estimada
- proposta comercial
- documentos
- historico
- status comercial

## Offline-first

O SQLite local e a fonte operacional imediata. A aplicacao deve abrir, consultar,
criar e editar dados mesmo sem internet.

Fluxo recomendado:

1. Usuario faz login no Supabase quando houver internet.
2. App baixa clientes, projetos e documentos para o SQLite.
3. Usuario trabalha no SQLite local.
4. App envia alteracoes para o Supabase quando houver sessao e rede.
5. Antes de substituir dados locais, o app gera backup local.

## Supabase

O Supabase e a camada de equipe:

- Auth: login por email/senha.
- Profiles: permissao, cargo, matricula e empresa.
- RLS: isolamento por empresa.
- Tables: clientes, projetos, documentos e historico.
- Storage: etapa futura para armazenar arquivos anexados e PDFs gerados.

## Modulos de servico

Servicos devem ficar desacoplados da interface:

- `ProjectService`: CRUD e regras de projeto.
- `FinancialAnalysisService`: ROI, TIR, VPL e fluxo de caixa.
- `ProposalPDFService`: exportacao profissional de proposta.
- `BillImporterService`: leitura de fatura PDF.
- `ProjectDocuments`: anexos do projeto.
- `SupabaseSync`: sincronizacao remota.

## Permissoes

Perfis comerciais:

- `assessor_projetos`: CRM e dimensionamento.
- `assessor_daf`: CRM, dimensionamento, financeiro e orcamentos.
- `diretor`: acesso total, incluindo editar/excluir clientes e projetos.

## Proximas fases comerciais

1. Adicionar fila de sincronizacao local para registrar operacoes pendentes.
2. Usar UUID nos registros principais para evitar conflito entre computadores.
3. Enviar documentos para Supabase Storage.
4. Criar tela de configuracoes da empresa.
5. Criar relatorio de auditoria por usuario.
6. Implementar empacotamento Windows assinado.
