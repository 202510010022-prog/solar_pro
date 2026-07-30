# Publicar o site publico do Solar Pro

O Play Console precisa de uma URL publica para a politica de privacidade e,
idealmente, uma pagina de exclusao de dados.

Arquivos prontos:

```text
public_site/index.html
public_site/privacy.html
public_site/data-deletion.html
public_site/support.html
public_site/styles.css
```

## Opcao 1: Netlify

Esta e a opcao mais simples para publicar uma pasta estatica.

1. Acesse Netlify.
2. Crie um novo site manual.
3. Envie a pasta `public_site`.
4. Copie a URL gerada.
5. Use no Play Console:

```text
Politica de privacidade: https://URL_DO_SITE/privacy.html
Exclusao de dados: https://URL_DO_SITE/data-deletion.html
Suporte: https://URL_DO_SITE/support.html
```

## Opcao 2: GitHub Pages

Boa opcao se o projeto estiver em um repositorio GitHub.

1. Suba a pasta `public_site` para o repositorio.
2. Configure Pages apontando para a pasta ou branch publicada.
3. Use as URLs finais no Play Console.

## Opcao 3: Supabase Storage publico

Funciona, mas exige configurar bucket publico e enviar os arquivos estaticos.
Use apenas se quiser manter tudo dentro do ecossistema Supabase.

## Testar antes de publicar

```bash
cd /home/kevinklecio96/solar_manager/public_site
python3 -m http.server 8080
```

Abra:

```text
http://localhost:8080/privacy.html
http://localhost:8080/data-deletion.html
http://localhost:8080/support.html
```

## Depois de publicar

Atualize estes arquivos com a URL final:

- `docs/play_console/STORE_LISTING.md`
- `docs/play_console/DATA_SAFETY.md`
- `docs/play_console/INTERNAL_TESTING.md`, se quiser deixar a URL anotada.
