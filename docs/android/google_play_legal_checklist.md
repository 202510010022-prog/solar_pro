# Google Play - checklist legal do Solar Pro

Status: preparação para publicação. Este documento não confirma que o Play
Console já foi configurado.

## URLs públicas

Preencher no Play Console após publicar o `public_site`:

- Privacy Policy URL: `https://URL_PUBLICA/privacy.html`
- Terms URL: `https://URL_PUBLICA/terms.html`
- Account deletion URL: `https://URL_PUBLICA/data-deletion.html`
- Support URL: `https://URL_PUBLICA/support.html`

## App content / políticas

Revisar antes de enviar:

- Data Safety.
- App access.
- Target audience.
- Location declaration.
- Account deletion declaration.
- Política de Privacidade.
- Termos de Uso.
- Link externo de exclusão de conta.
- Caminho dentro do app para iniciar solicitação de exclusão.

## Data Safety - categorias para revisão

A declaração final deve refletir o comportamento da versão efetivamente
publicada. Revisar especialmente:

- informações de conta;
- nome e e-mail;
- dados de clientes;
- endereço e CEP;
- localização precisa ou aproximada quando o usuário aciona recursos de GPS;
- informações financeiras de projetos;
- conteúdo de feedback;
- identificadores de usuário;
- cache local e arquivos gerados;
- fornecedores usados para autenticação, banco, geocodificação, CEP e PVGIS.

## Antes de publicar

1. Confirmar que o site público está em HTTPS.
2. Testar `privacy.html`, `terms.html`, `data-deletion.html` e `support.html`.
3. Configurar `LEGAL_BASE_URL` no build Android.
4. Conferir se a página de exclusão permite solicitar exclusão fora do app.
5. Conferir se o app possui caminho interno para solicitar exclusão.
6. Confirmar que não há senha, token, chave privada ou dado sensível nos
   documentos públicos.
7. Revisar se os documentos ainda usam os dados corretos de responsável e
   contato.
