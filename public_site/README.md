# Solar Pro public site

Mini-site estatico para usar na Play Store:

- `index.html`: pagina inicial simples.
- `privacy.html`: politica de privacidade publica.
- `data-deletion.html`: instrucao de exclusao de dados.
- `support.html`: contato de suporte.

## Antes de publicar

Troque este contato se criar um email comercial:

- `kevinklecio96@gmail.com`
- `Kevin Klecio`

## Como testar localmente

```bash
cd public_site
python3 -m http.server 8080
```

Depois abra:

```text
http://localhost:8080/privacy.html
```

## Hospedagem sugerida

Pode hospedar em GitHub Pages, Netlify, Vercel, Cloudflare Pages ou Supabase
Storage configurado como publico.
