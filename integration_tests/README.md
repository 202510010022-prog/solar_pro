# Solar Pro Integration Tests

Testes de integração para validar regras de RLS, bloqueio de empresa e
isolamento multi-tenant no Supabase de teste.

> ATENCAO: NUNCA aponte este `.env` para um banco de producao. Estes testes
> criam e DELETAM dados reais no projeto Supabase configurado.

## Configuracao

Crie o arquivo local de ambiente:

```bash
cp integration_tests/.env.example integration_tests/.env
```

Preencha:

```env
SUPABASE_URL=https://SEU_PROJETO.supabase.co
SUPABASE_ANON_KEY=SUA_CHAVE_ANON_OU_PUBLISHABLE_AQUI
SUPABASE_SERVICE_ROLE_KEY=SUA_SERVICE_ROLE_KEY_AQUI
```

O arquivo `integration_tests/.env` fica fora do Git pelo `.gitignore`.

## Instalar Dependencias

```bash
cd integration_tests
dart pub get
```

## Rodar Testes

```bash
cd integration_tests
dart test
```

Nesta primeira etapa, a infraestrutura cria fixtures com:

- Empresa A ativa
- Empresa B bloqueada
- 1 usuario admin e 1 usuario comum para cada empresa

Os testes de cenario serao adicionados depois.
