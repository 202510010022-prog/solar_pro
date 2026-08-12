# Solar Pro public site

Mini-site estático para documentação pública do Solar Pro:

- `index.html`: índice de documentos e suporte.
- `privacy.html`: Política de Privacidade.
- `terms.html`: Termos de Uso.
- `data-deletion.html`: Exclusão de Conta e Dados.
- `support.html`: Suporte, Privacidade e Direitos LGPD.
- `styles.css`: estilos compartilhados.

## Identificação pública atual

- Produto: Solar Pro
- Responsável: Kevin Klecio
- Contato: `kevinklecio96@gmail.com`

## Como testar localmente

```bash
cd public_site
python3 -m http.server 8080
```

Depois abra:

```text
http://localhost:8080/
http://localhost:8080/privacy.html
http://localhost:8080/terms.html
http://localhost:8080/data-deletion.html
http://localhost:8080/support.html
```

## Antes de publicar na Play Store

1. Hospedar o diretório `public_site`.
2. Confirmar que as páginas funcionam por HTTPS.
3. Testar as URLs públicas de privacidade, termos, exclusão e suporte.
4. Configurar `LEGAL_BASE_URL` no build Android.
5. Preencher URLs no Play Console.
6. Revisar o formulário Data Safety.
7. Revisar o contato legal publicado.

## Hospedagem sugerida

Pode hospedar em GitHub Pages, Netlify, Vercel, Cloudflare Pages ou Supabase
Storage configurado como público.
