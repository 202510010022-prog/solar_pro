# Play Console - Teste Interno

Roteiro para subir o primeiro AAB do Solar Pro em teste interno.

## Arquivo AAB

Use o artefato preparado:

```text
/home/kevinklecio96/.solarpro/releases/0.1.0+2001/solarpro-0.1.0+2001.aab
```

## Passos no Play Console

1. Criar app:
   - Nome: Solar Pro.
   - Idioma padrao: Portugues (Brasil).
   - Tipo: App.
   - Gratuito ou pago: definir conforme estrategia comercial.

2. Configurar acesso ao app:
   - Informar que o app exige login.
   - Criar uma conta de teste no Supabase.
   - Preencher email e senha diretamente no Play Console.
   - Nao salvar senha neste repositorio.

3. Preencher conteudo do app:
   - Politica de privacidade.
   - Seguranca dos dados.
   - Classificacao de conteudo.
   - Publico-alvo.
   - Declaracao de anuncios: provavelmente "Nao", se nao houver ads.

4. Criar trilha de teste interno:
   - Menu: Teste e lancamento > Teste interno.
   - Criar nova versao.
   - Enviar o AAB.
   - Informar notas de versao.
   - Salvar e revisar.
   - Iniciar lancamento para teste interno.

5. Adicionar testadores:
   - Criar lista de emails.
   - Incluir seu email e emails da equipe.
   - Enviar link de teste.

## Conta de teste

Preencha manualmente no Play Console:

```text
Email: PREENCHER_EMAIL_TESTE
Senha: PREENCHER_SENHA_TESTE_NO_PLAY_CONSOLE
Observacao: Usuario precisa ter dados suficientes para a revisao navegar.
```

## Validacao antes de enviar

- AAB release enviado, nao APK debug.
- Login de teste funciona.
- Dashboard abre sem dados quebrados.
- Navegacao: Inicio, CRM, Projetos, Dimensionar, Financeiro e Mais.
- Criar cliente funciona.
- Criar projeto/dimensionamento funciona.
- Financeiro abre sem erro.
- Relatorios nao travam o app.
- Nao ha texto de debug visivel.
