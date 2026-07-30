# Solar Manager Desktop

Aplicativo desktop offline para cadastrar clientes, calcular projetos
fotovoltaicos com consumo/HSP mês a mês, simular financiamento e acompanhar
projetos por status.

O projeto técnico é a etapa técnica. O valor do projeto e o payback são
definidos na aba de financiamento.

A aba de gráficos mostra Consumo x Geração x Saldo mês a mês para o projeto
selecionado.

## Rodar em modo desenvolvimento

```bash
python desktop_app/main.py
```

## Gerar executável

Depois de instalar o PyInstaller:

```bash
pyinstaller --onefile --windowed --name SolarManager desktop_app/main.py
```

O banco SQLite fica em:

```text
desktop_app/solar_manager_desktop.db
```
