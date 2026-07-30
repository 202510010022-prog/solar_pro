# 🎯 ONE CLICK BUILD PARA WINDOWS

## ✨ Novo Script Automático!

Agora é **MUITO** mais fácil. Só precisa fazer **1 coisa**:

---

## 🚀 **Passo 1: Abra `build_windows.bat` (duplo clique)**

Isso é tudo! O script vai:

1. ✅ Criar ambiente virtual (se não existir)
2. ✅ Instalar dependências automaticamente
3. ✅ Gerar `SolarPro.exe`
4. ✅ Criar `SolarPro_Portable_*.zip` (se escolher opção 2)
5. ✅ Mostrar resumo final

---

## 📋 **Menu de Opções:**

```
Escolha uma opção:

  1) Gerar SolarPro.exe SOMENTE
  2) Gerar SolarPro.exe + ZIP portável 🎁 (RECOMENDADO)
  3) Limpar e refazer tudo (se teve erro)
  0) Sair
```

### Recomendação: **Escolha 2** (ZIP portável)

---

## ⏱️ **Quanto Tempo Leva?**

- Python 3.8+ já instalado: **1-3 minutos**
- Primeira vez (instala Python): **5-10 minutos**

---

## 📦 **Resultado Final:**

Após completar, você terá:

```
seu_projeto/
├── dist/
│   └── SolarPro.exe              ← Executável
└── SolarPro_Portable_*.zip        ← ZIP portável
```

---

## 🎁 **Opção 2 (Recomendada) gera:**

- ✅ `dist/SolarPro.exe` (~150-200 MB)
- ✅ `SolarPro_Portable_*.zip` (~100-150 MB)

**ZIP é melhor para compartilhar!**

---

## 📤 **Como Compartilhar:**

### **Copiar para outro PC:**
```
1. Descompacte SolarPro_Portable_*.zip
2. Execute SolarPro.exe
3. Pronto! Funciona em qualquer Windows
```

### **Enviar por Email/Drive:**
```
1. Abra Google Drive
2. Suba SolarPro_Portable_*.zip
3. Compartilhe o link
4. Pronto!
```

### **Copiar em Pendrive:**
```
1. Copie pasta dist/ para o pendrive
2. No outro PC, abra pendrive\SolarPro.exe
3. Pronto!
```

---

## ❌ **Se der erro:**

### Erro: "Python não encontrado"
```
1. Baixe Python: https://www.python.org/downloads/
2. Instale marcando "Add Python to PATH"
3. Abra novo CMD e tente novamente
```

### Erro: "Módulo não encontrado"
```
Escolha opção "3" no menu para limpar e refazer
```

### Erro: "Acesso negado"
```
Clique direito em build_windows.bat → "Executar como administrador"
```

---

## 🎨 **Personalizações (Avançado):**

Se quiser mudar nome ou ícone:

1. Edite `SolarPro.spec`
2. Mude `name='SolarPro'` para outro nome
3. Mude `icon=['...']` para outro ícone

---

## ✅ **Checklist:**

- [ ] Copiei `build_windows.bat` para o projeto
- [ ] Duplo clique em `build_windows.bat`
- [ ] Escolhi opção 2
- [ ] Aguardei 1-3 minutos
- [ ] Tenho `SolarPro_Portable_*.zip` pronto
- [ ] Posso descompactar e rodar em outro PC

---

## 🎉 **Pronto!**

Você tem um programa Windows portável e pronto para distribuir! 

**Dúvidas?** Veja [COPIAR_PARA_WINDOWS.md](COPIAR_PARA_WINDOWS.md) para mais detalhes.
