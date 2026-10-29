# Caixinha Digital

Organizador de remédios para idosos — Grupo 2, Empreendedorismo (UENP).
Flutter (Dart) + Supabase. Recriado a partir do protótipo navegável da Sprint 5.

## 1. Rodar o projeto

```bash
# dentro da pasta caixinha_digital
flutter create . --org br.uenp --platforms web,android,ios   # gera as pastas android/ios/web
flutter pub get
flutter analyze
flutter run -d chrome          # ou: flutter run  (celular/emulador)
```

`flutter create .` não sobrescreve os arquivos que já existem em `lib/`.

## 2. Configurar o Supabase (uma vez só, no painel)

Projeto: **caixinha-digital** (`vmxlyeosgmrtjpvvgnje`) — tabelas, regras de segurança e dados de exemplo já estão criados.

1. **Authentication → Sign In / Providers → "Allow anonymous sign-ins": LIGAR**
   (é assim que o idoso entra só com o código, sem senha).
2. **Authentication → Sign In / Providers → Email → "Confirm email": DESLIGAR**
   (só durante o desenvolvimento, para o cuidador entrar logo após criar a conta).

## 3. Testar

| Quem | Como entrar |
|---|---|
| Idoso (Sra. Maria) | "Tenho um código" → `024587` |
| Cuidador | "Sou cuidador" → criar conta → "Adicionar usuário existente" → `20262026` |

Dica para a apresentação: abra o idoso no celular e o cuidador no navegador.
Quando ela toca em "Já tomei", o painel do cuidador atualiza sozinho.

## 4. Estrutura

```
lib/
  main.dart                 inicialização + leitura do link /#/entrar/CODIGO
  config.dart               URL e chave pública do Supabase
  tema.dart                 cores e fontes (diretrizes de IHC)
  dados/
    modelos.dart            Idoso, DoseHoje, Medicamento, Horario, Documento, Turno
    repositorio.dart        TODAS as chamadas ao Supabase
  widgets/comuns.dart       BotaoVoltar, Secao, FotoDoStorage...
  telas/
    inicio_tela.dart        decide: idoso / cuidador / tela de escolha
    idoso/                  entrar com código, caixinha, tomar remédio, foto, consulta de hoje
    cuidador/               login, primeiro acesso, criar pessoa, painel,
                            cadastro de remédio, receita/exame, configurações
supabase/migrations/        SQL do banco (já aplicado)
```

## 5. Requisitos atendidos

| RF | O que faz | Onde |
|---|---|---|
| RF01 | Confirmação "Já tomei" em 1 toque, cores amarelo/verde | `tomar_remedio_tela.dart` |
| RF02 | Entrada sem senha (código de 6 números / link) | `entrar_codigo_tela.dart`, função `entrar_como_idoso` |
| RF03 | Cadastro de remédio pelo cuidador, vários horários | `remedio_form_tela.dart` |
| RF04 | Dose não marcada 60 min depois aparece "Atrasado" no painel | função `doses_de_hoje` |
| RF05 | Receitas e exames com foto + "Consulta de hoje" | `consulta_tela.dart`, `documento_form_tela.dart` |
| RF06 | "Hoje: X de 3 tomados", zera à meia-noite (horário de Brasília) | `home_idoso_tela.dart` |
| RF07 | Vibração + som ao confirmar (liga/desliga nas configurações) | `tomar_remedio_tela.dart` |
| — | "Marquei por engano" (desfazer) | `tomar_remedio_tela.dart` |

## 6. Segurança (resumo para o dossiê)

- Regras **RLS** em todas as tabelas: cada pessoa só vê os dados de quem ela acompanha.
- Idoso pode **marcar/desmarcar dose**, mas **não** pode cadastrar ou apagar remédios.
- Fotos ficam em bucket **privado**; o app usa links temporários (1 hora).
- Limite de 5 códigos errados a cada 10 minutos (contra tentativa e erro).

## 7. Próximos passos (v2)

- **Lembrete no celular** na hora do remédio (`flutter_local_notifications`).
- **Aviso real ao cuidador** pelo WhatsApp (Edge Function + `pg_cron` + API do WhatsApp).
  Hoje as chaves "Remédio não marcado" e "Resumo do dia" só guardam a preferência.
- Publicar a versão web (ex.: Vercel). No navegador o link do WhatsApp já usa o endereço
  aberto (`Config.linkBase`); `Config.urlApp` só vale para o app instalado (Android/iOS).
