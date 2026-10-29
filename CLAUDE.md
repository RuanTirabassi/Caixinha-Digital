# Caixinha Digital

Organizador de remédios para idosos (Grupo 2, Empreendedorismo, UENP).
App Flutter (web, Android, iOS) com backend no Supabase, publicado na Vercel.

O projeto Flutter fica na pasta `caixinha_digital/`. Rode todos os comandos
`flutter` de dentro dela (na raiz dá "No pubspec.yaml file found").
Como rodar e testar: `caixinha_digital/README.md`.

## Regra: toda mudança sobe a versão

A cada mudança no app, antes do commit:

1. Suba `version:` em `caixinha_digital/pubspec.yaml` (regras no topo do CHANGELOG;
   o número depois do `+` sobe 1 em toda versão).
2. Escreva uma entrada no topo de `caixinha_digital/CHANGELOG.md` com data,
   o que mudou e por quê, incluindo configurações feitas fora do código
   (painel do Supabase, Vercel etc.).
3. Se mudou alguma configuração descrita abaixo, atualize este arquivo também.

## Onde está cada coisa

| O quê | Onde |
|---|---|
| Acesso ao banco (todas as consultas) | `lib/dados/repositorio.dart` |
| Modelos (Idoso, Medicamento, DoseHoje...) | `lib/dados/modelos.dart` |
| URL e chave pública do Supabase, link do WhatsApp | `lib/config.dart` |
| Botões, cartões e seções reutilizados | `lib/widgets/comuns.dart` |
| Cores e estilos de texto | `lib/tema.dart` |
| Telas do cuidador / do idoso | `lib/telas/cuidador/`, `lib/telas/idoso/` |
| Estrutura do banco | `supabase/migrations/*.sql` |

## Supabase (banco e login)

- Projeto **caixinha-digital**, id `vmxlyeosgmrtjpvvgnje`.
- A chave em `lib/config.dart` é a pública (anon). Quem protege os dados são as regras RLS.
- Migrações aplicadas: `001_schema_inicial`, `002_dados_exemplo`, `003_telas_figma`.
- **Migração nova:** crie `supabase/migrations/00N_nome.sql` e aplique no banco
  (SQL Editor do painel ou ferramenta do Supabase). Commitar o arquivo **não**
  aplica nada. Se o app mostrar "O banco ainda não foi atualizado", falta aplicar.
- Configurações do painel:
  - Authentication → Sign In / Providers: **Anonymous sign-ins precisa estar ligado**
    (o idoso entra só com o código de 6 dígitos).
  - Authentication → URL Configuration: Site URL `https://caixinha-digital.vercel.app`
    e Redirect URL `https://caixinha-digital.vercel.app/**`.

## Vercel (site na web)

- Endereço: **https://caixinha-digital.vercel.app** (domínio gratuito).
- Projeto Vercel `caixinha-digital`, ligado ao GitHub `RuanTirabassi/Caixinha-Digital`,
  Root Directory `caixinha_digital`.
- **Cada push na `main` publica sozinho** (uns 3 minutos). Pushes em outras
  branches geram uma versão de teste com endereço próprio.
- `caixinha_digital/vercel.json`: a Vercel não tem Flutter, então o build clona o
  Flutter **3.44.8** e roda `flutter build web`. Ao atualizar o Flutter local,
  troque a versão nesse arquivo também.
- Proteção: o endereço principal é público. As versões de teste pedem login na Vercel.
- O app usa rotas com `#` (ex.: `/#/entrar/123456`), então não precisa de rewrites.

## Cuidados

- `Material` não aceita `shape` e `borderRadius` juntos (dá erro vermelho na tela).
- `flutter test` roda só os testes de unidade. `flutter test test_integracao`
  usa o Supabase de verdade e cria um cuidador e uma pessoa de teste no banco.
- Os avisos "LF will be replaced by CRLF" do git são só de quebra de linha.
