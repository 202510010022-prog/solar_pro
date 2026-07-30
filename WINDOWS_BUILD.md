# 🪟 Guia de Build para Windows

## ✅ Pré-requisitos

Você está usando Windows! Ótimo. Antes de começar:

1. **Python 3.8+** instalado (baixe em python.org)
2. **Git** instalado (opcional, para clonar o projeto)

---

## 📋 Passo 1: Preparar o Ambiente

### 1.1 Clonar o repositório (ou extrair pasta)
```bash
cd seu_local_de_trabalho
git clone <seu-repositorio>
cd solar_manager
```

### 1.2 Criar e ativar ambiente virtual
```bash
# Criar
python -m venv venv

# Ativar (Windows CMD)
venv\Scripts\activate

# Ativar (Windows PowerShell)
venv\Scripts\Activate.ps1
```

### 1.3 Instalar dependências
```bash
pip install -r requirements.txt
```

---

## 🔨 Passo 2: Gerar Executáveis

### **Opção A: SolarPro (Recomendado - Interface Qt)**

```bash
pyinstaller SolarPro.spec
```

Resultado: `dist/SolarPro.exe`

### **Opção B: SolarManager (Interface Tkinter - Simples)**

```bash
pyinstaller SolarManager.spec
```

Resultado: `dist/SolarManager.exe`

### **Opção C: Ambos ao mesmo tempo**

```bash
pyinstaller SolarPro.spec && pyinstaller SolarManager.spec
```

---

## 📂 Arquivos Inclusos nos Executáveis

O PyInstaller automaticamente empacota:

✅ **SolarPro.exe**
- `desktop_app_qt/assets/` (ícones e imagens)
- `desktop_app_qt/service_account.json` (credenciais Google)
- `desktop_app/` (lógica de negócio)
- Banco de dados SQLite

✅ **SolarManager.exe**
- `desktop_app/` (lógica de negócio)
- `desktop_app/sheets_config.json` (config)
- Banco de dados SQLite

---

## 🚀 Executar

Após o build, você encontrará os `.exe` em:

```
solar_manager/
├── dist/
│   ├── SolarPro.exe        👈 Use este!
│   └── SolarManager.exe    👈 Ou este
```

**Simplesmente clique duplo para rodar!**

---

## 📊 Dados Persistem

Os dados são salvos em:

- **Windows (SolarPro)**: `C:\Users\<seu-usuario>\AppData\Local\SolarPro\`
- **Windows (SolarManager)**: Mesma pasta do `.exe`

> Nota: O banco de dados fica junto com o executável ou em AppData (dependendo da configuração)

---

## 🔧 Solução de Problemas

### Erro: "Python não encontrado"
- Verifique se Python está no PATH
- Execute o instalador Python novamente e marque "Add Python to PATH"

### Erro: "Módulo não encontrado"
- Verifique `requirements.txt`
- Execute `pip install -r requirements.txt` novamente

### Erro ao conectar Google Sheets
- Verifique se `service_account.json` está na pasta do `.exe`
- Recrie a chave de serviço no Google Cloud Console

### Executável muito grande
- Normal! Inclui Python + todas as dependências
- Você pode compactar com ZIP se precisar

---

## 📝 Personalizações (Avançado)

Se quiser modificar o spec file:

```bash
# Editar
code SolarPro.spec
# ou
notepad SolarPro.spec
```

Opções úteis:
```python
# Adicionar mais dados
datas=[('seu_arquivo.json', '.')]

# Adicionar mais módulos ocultos
hiddenimports=['seu_modulo']

# Mudar o ícone
icon=['seu_icon.ico']

# Mudar tamanho de window
# (modificar no source code, não aqui)
```

---

## ✨ Dicas Extras

- **Crie um atalho** do `.exe` para sua área de trabalho
- **Crie um instalador** usando NSIS (Advanced Installer, InnoSetup)
- **Atualize versão** em requirements.txt conforme melhora

---

Pronto? Rode o build! 🎉
