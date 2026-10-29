# Histórico de mudanças

Toda mudança no app sobe a versão em `pubspec.yaml` e ganha uma entrada aqui
(a mais nova fica em cima). Formato da versão: `MAIOR.MENOR.CORREÇÃO+BUILD`.

- **CORREÇÃO** (1.0.0 → 1.0.1): conserto de erro, sem mudar o que a pessoa vê.
- **MENOR** (1.0.1 → 1.1.0): tela ou função nova, ou mudança visível.
- **MAIOR** (1.1.0 → 2.0.0): mudança grande que quebra o que existia.
- **BUILD** (`+2` → `+3`): sobe 1 em **toda** versão, sem exceção.

---

## 1.1.0+2 — 29/10/2026

**Telas**
- Painel do cuidador: a engrenagem de Configurações foi para o topo, ao lado do
  nome da pessoa. Antes ela ficava por cima do quadro "Enviar link pelo WhatsApp".
- Tela inicial do idoso: a engrenagem (que só servia para sair) virou um botão
  **Sair** com ícone, no canto superior direito. Continua pedindo confirmação.

**Testes**
- `test_integracao/fluxo_completo_test.dart`: toca no "Sair" de dentro do aviso,
  porque agora existem dois textos "Sair" na tela.

**Projeto**
- Criados `CLAUDE.md` (na raiz do repositório) e este `CHANGELOG.md`.

## 1.0.0+1 — 29/10/2026

Mudanças feitas antes de existir a regra de versão (a versão ficou 1.0.0+1).

**Correções**
- Tela de Configurações dava erro vermelho (`shape != null && borderRadius != null`):
  o `Material` dos botões com borda recebia `shape` e `borderRadius` juntos
  (`lib/widgets/comuns.dart`).
- Várias telas davam erro de banco porque a migração `003_telas_figma.sql` nunca
  tinha sido aplicada no Supabase. Foi aplicada pelo SQL Editor do painel.

**Publicação na web**
- App publicado na Vercel: https://caixinha-digital.vercel.app
- `vercel.json`: a Vercel baixa o Flutter 3.44.8 e gera `build/web`.
- Cada `git push` na `main` publica sozinho (leva uns 3 minutos).
- Link do WhatsApp (`Config.urlApp`) aponta para o endereço da Vercel.
- Supabase → Authentication → URL Configuration: Site URL e Redirect URLs
  apontam para o endereço da Vercel.
