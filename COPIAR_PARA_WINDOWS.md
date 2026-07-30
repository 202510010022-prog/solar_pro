# 📦 Copiar Programa para Windows (Simples)

Seu objetivo: **Um arquivo `.exe` que você pode copiar para qualquer PC Windows**

## ✅ Opção 1: Super Simples (Recomendado)

### Passo 1: No Windows, abra o PowerShell/CMD

```bash
cd C:\Users\seu-usuario\Downloads\solar_manager
```

### Passo 2: Clique 2x em `build_windows.bat`

Pronto! Um menu vai aparecer. Escolha:
- **1** = Gera só o `.exe`
- **2** = Gera `.exe` + `.zip` portável

### Passo 3: Pronto! 🎉

Seu executável está em: `dist\SolarPro.exe`

---

## 📋 O que você pode fazer com o `.exe`

### **Copiar para outro PC**
```
1. Copiar: dist\SolarPro.exe
2. Colar em qualquer pasta do outro PC
3. Clicar 2x para rodar
```

✅ **Funciona em qualquer Windows 7+**

---

## 🎁 Versão Portável (Opcional)

Se você quer compartilhar como arquivo único:

```
dist\
├── SolarPro.exe      ← Executável principal
├── *.dll             ← Dependências
├── _internal\        ← Arquivos internos
└── (outros arquivos)
```

**Comprimir tudo em ZIP:**
```bash
# Pelo menu (opção 2), ou:
# Botão direito na pasta dist/ → Enviar para → Pasta Compactada (ZIP)
```

Resultado: `SolarPro.zip` (📦 ~200MB)

---

## 🔧 Passo a Passo Completo (Windows)

### 1️⃣ **Preparar Ambiente**

```bash
# Abrir PowerShell/CMD como Administrador
# Navegar até a pasta
cd C:\caminho\solar_manager

# Criar ambiente virtual (1ª vez só)
python -m venv venv

# Ativar
venv\Scripts\activate

# Instalar dependências
pip install -r requirements.txt
```

### 2️⃣ **Gerar Executável**

**Opção A: Menu Automático** (Mais fácil)
```bash
# Duplo clique em build_windows.bat
# Escolha opção 1 ou 2
```

**Opção B: Linha de Comando** (Mais rápido)
```bash
pyinstaller SolarPro.spec
```

### 3️⃣ **Resultado**

```
dist\SolarPro.exe  ← USE ESTE!
```

Copie para:
- ✅ Outro PC
- ✅ Pendrive
- ✅ Google Drive / OneDrive
- ✅ Envie por email
- ✅ Coloque em servidor

---

## 📦 Tamanho do Programa

| Tipo | Tamanho |
|------|---------|
| `SolarPro.exe` (só) | ~150-200 MB |
| `dist/` completo | ~300-400 MB |
| `SolarPro.zip` | ~150-200 MB (comprimido) |

---

## 🎯 Casos de Uso

### **Caso 1: Compartilhar com 1 pessoa**
```
Envie: dist\SolarPro.exe por email
```

### **Caso 2: Compartilhar com vários**
```
1. Comprima: dist → SolarPro.zip
2. Suba em Google Drive / OneDrive
3. Compartilhe link
```

### **Caso 3: Colocar em rede corporativa**
```
1. Copie dist\SolarPro.exe para pasta compartilhada
2. Usuários executam de lá
```

### **Caso 4: Colocar no pendrive**
```
1. Copie dist\ inteiro para pendrive
2. No outro PC: pendrive\SolarPro.exe
```

---

## ❓ Dúvidas Frequentes

### **P: Preciso instalar algo no PC destino?**
R: **Não!** Apenas Windows 7+ instalado.

### **P: Funciona sem internet?**
R: **Sim!** Totalmente offline (Google Sheets offline também).

### **P: Como distribuir atualizações?**
R: Gere novo `.exe` e distribua de novo. Ou use um instalador (veja abaixo).

### **P: Pode customizar o nome/ícone?**
R: Sim! Edite `SolarPro.spec` e mude `name='SolarPro'` para outro nome.

---

## 🎨 Opção Avançada: Criar Instalador

Se quer criar um instalador `.msi` ou `.exe` instalável:

### Opção 1: **NSIS** (Gratuito, recomendado)
```bash
# Baixe: https://nsis.sourceforge.io/
# Crie nsis_installer.nsi
# Compile com NSIS
```

### Opção 2: **Inno Setup** (Gratuito, mais fácil)
```bash
# Baixe: https://jrsoftware.org/isbundle.php
# Crie setup.iss
# Compile
```

### Resultado:
```
SolarPro_Installer.exe ← Um clique para instalar!
```

---

## 📝 Resumo Final

| Você quer... | Faça isto |
|---|---|
| Copiar `.exe` para outro PC | Use `dist\SolarPro.exe` |
| Enviar por email | Comprima em `.zip` |
| Instalar como programa | Crie instalador (NSIS/InnoSetup) |
| Colocar em compartilha | Copie pasta `dist\` |
| Atualizar versão | Refaça build com `build_windows.bat` |

---

**Dúvidas? Tudo rodando?** 🚀
