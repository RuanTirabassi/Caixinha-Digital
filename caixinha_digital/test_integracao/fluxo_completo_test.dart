// Teste de integração: usa as telas de verdade e o Supabase de verdade.
// Toca nos botões como uma pessoa faria e confere no banco se gravou.
//
// Rodar:  flutter test test_integracao
//
// Cria um cuidador e uma pessoa "Teste Automatizado <hora>" — não mexe
// nos dados da Sra. Maria (só vincula o cuidador de teste a ela).
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:caixinha_digital/config.dart';
import 'package:caixinha_digital/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// PNG 1x1 válido (usado como "foto" do remédio e do exame)
final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

class _CameraFalsa extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  int chamadas = 0;
  @override
  Future<XFile?> getImageFromSource(
      {required ImageSource source, ImagePickerOptions options = const ImagePickerOptions()}) async {
    chamadas++;
    return XFile.fromData(_png, name: 'teste.png', mimeType: 'image/png');
  }
}

class _NavegadorFalso extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final abertos = <String>[];
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> canLaunch(String url) async => true;
  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    abertos.add(url);
    return true;
  }
}

final _resultado = <String>[];
void passo(String s) {
  _resultado.add('OK  $s');
  // ignore: avoid_print
  print('OK  $s');
}

SupabaseClient get db => Supabase.instance.client;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final camera = _CameraFalsa();
  final navegador = _NavegadorFalso();

  setUpAll(() async {
    HttpOverrides.global = null; // o flutter_test bloqueia a rede por padrão
    SharedPreferences.setMockInitialValues({});
    ImagePickerPlatform.instance = camera;
    UrlLauncherPlatform.instance = navegador;
    await initializeDateFormatting('pt_BR');
    await Supabase.initialize(
      url: Config.supabaseUrl,
      publishableKey: Config.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
    );
  });

  testWidgets('fluxo completo cuidador + idoso gravando no Supabase', (t) async {
    t.view.physicalSize = const Size(900, 5000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    // vibração e som (RF07) passam por este canal
    final plataforma = <String>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      plataforma.add(c.method);
      return null;
    });

    // ---------- helpers ----------
    // A chamada roda na zona do teste (o cliente do Supabase usa timers
    // dela); enquanto isso o relógio falso e a rede real vão andando.
    Future<R> rede<R>(Future<R> Function() f) async {
      late R valor;
      Object? erro;
      var feito = false;
      f().then((v) {
        valor = v;
        feito = true;
      }, onError: (Object e) {
        erro = e;
        feito = true;
      });
      final fim = DateTime.now().add(const Duration(seconds: 30));
      while (!feito) {
        if (DateTime.now().isAfter(fim)) throw TestFailure('Chamada ao Supabase sem resposta');
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await t.pump(const Duration(milliseconds: 50));
      }
      if (erro != null) throw erro!;
      return valor;
    }

    Future<void> esperar(Finder f, {int segundos = 25}) async {
      final fim = DateTime.now().add(Duration(seconds: segundos));
      while (DateTime.now().isBefore(fim)) {
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 120)));
        await t.pump(const Duration(milliseconds: 60));
        if (f.evaluate().isNotEmpty) return;
      }
      throw TestFailure('Não apareceu na tela: ${f.describeMatch(Plurality.one)}');
    }

    Future<void> sumir(Finder f, {int segundos = 25}) async {
      final fim = DateTime.now().add(Duration(seconds: segundos));
      while (DateTime.now().isBefore(fim)) {
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 120)));
        await t.pump(const Duration(milliseconds: 60));
        if (f.evaluate().isEmpty) return;
      }
      throw TestFailure('Não sumiu da tela: ${f.describeMatch(Plurality.one)}');
    }

    Future<void> tocar(Finder f) async {
      // ignore: avoid_print
      print('    tocar ${f.describeMatch(Plurality.one)}');
      await esperar(f);
      await t.pump(const Duration(milliseconds: 500)); // termina animação de diálogo/menu
      await t.ensureVisible(f.first);
      await t.pump();
      await t.tap(f.first, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 300));
    }

    Future<void> digitar(int indiceCampo, String texto) async {
      await esperar(find.byType(TextField));
      await t.enterText(find.byType(TextField).at(indiceCampo), texto);
      await t.pump();
    }

    Finder texto(String s) => find.text(s);
    Finder contem(String s) => find.textContaining(s, findRichText: true);

    final run = DateTime.now().millisecondsSinceEpoch.toString();
    final sobrenome = 'Automatizado $run';
    final email = 'teste.caixinha.$run@example.com';
    final senha = 'T${Random().nextInt(1 << 32)}x!';
    final anonimos = <String>[];

    // =============== 1. ABERTURA ===============
    await t.pumpWidget(const CaixinhaApp());
    await esperar(texto('TENHO UM CÓDIGO'));
    expect(texto('Sou cuidador / familiar'), findsOneWidget);
    passo('Tela inicial abre com os dois botões');

    // =============== 2. CUIDADOR: CRIAR CONTA ===============
    await tocar(texto('Sou cuidador / familiar'));
    await esperar(texto('Entrar como cuidador'));
    await tocar(texto('Entrar')); // vazio -> validação
    await esperar(contem('Informe um e-mail válido'));
    passo('Login vazio mostra aviso de validação');

    await tocar(texto('Ainda não tenho conta'));
    await esperar(texto('Criar conta de cuidador'));
    await digitar(0, email);
    await digitar(1, senha);
    await tocar(texto('Criar conta'));
    await esperar(texto('Sem usuário cadastrado'));
    final cuidadorId = db.auth.currentUser!.id;
    passo('Criar conta de cuidador -> tela "Sem usuário cadastrado"');

    // código de cuidador errado
    await tocar(texto('Adicionar usuário existente'));
    await esperar(find.byType(AlertDialog));
    await t.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), '11112222');
    await tocar(texto('Adicionar'));
    await esperar(texto('Código não encontrado.'));
    passo('Código de cuidador errado -> "Código não encontrado."');

    // =============== 3. CRIAR A PESSOA ===============
    await tocar(texto('Criar usuário'));
    await esperar(texto('Adicionar Usuário'));
    await digitar(0, 'Teste');
    await digitar(1, sobrenome);
    await tocar(texto('Senhora'));
    await digitar(2, '43999990000');
    await tocar(texto('Continuar'));
    await esperar(texto('Painel da Sra. Teste'));
    final idoso = await rede(() => db.from('idosos').select().eq('sobrenome', sobrenome).single());
    final idosoId = idoso['id'] as String;
    expect(idoso['tratamento'], 'senhora');
    expect(idoso['whatsapp'], '5543999990000');
    expect((idoso['codigo_acesso'] as String).length, 6);
    passo('Criar usuário -> gravou em "idosos" (tratamento, WhatsApp, código de 6 dígitos)');

    // =============== 4. CADASTRAR REMÉDIO (RF03) ===============
    await tocar(texto('Adicionar remédio'));
    await esperar(texto('Cadastro Remédios'));
    await tocar(texto('Salvar')); // vazio
    await esperar(texto('Preencha o nome e quanto tomar.'));
    passo('Salvar remédio vazio mostra aviso');

    await digitar(0, 'Losartana Teste');
    await digitar(1, '1 comprimido de 50mg');
    await digitar(2, 'Para pressão');
    await tocar(texto('12 : 00'));
    await esperar(texto('OK'));
    await tocar(texto('OK'));
    passo('Relógio do horário abre e fecha (OK)');
    await tocar(texto('Adicionar mais um horário'));
    await esperar(texto('20 : 00'));
    await tocar(texto('Adicionar foto (opcional)'));
    await tocar(texto('Escolher da galeria'));
    await esperar(texto('Trocar foto'));
    await tocar(find.byIcon(Icons.circle_outlined)); // formato redondo
    await tocar(texto('Azul'));
    await tocar(texto('Salvar'));
    await esperar(texto('Losartana Teste • 1 comprimido de 50mg'));
    var remedio = await rede(() => db
        .from('medicamentos')
        .select('*, horarios(*)')
        .eq('idoso_id', idosoId)
        .single());
    final remedioId = remedio['id'] as String;
    final horarios = (remedio['horarios'] as List).cast<Map<String, dynamic>>();
    expect(horarios.map((h) => h['turno']).toSet(), {'almoco', 'noite'});
    expect(remedio['formato'], 'redondo');
    expect(remedio['cor'], 'Azul');
    expect(remedio['finalidade'], 'Para pressão');
    expect(remedio['foto_path'], startsWith('$idosoId/'));
    var arquivos = await rede(() => db.storage.from('arquivos').list(path: idosoId));
    expect(arquivos.length, 1);
    passo('Cadastrar remédio -> "medicamentos" + 2 "horarios" (almoço/noite) + foto no Storage');

    // editar: muda a dose, adiciona e remove horário
    await tocar(find.byIcon(Icons.edit));
    await esperar(texto('Editar Remédio'));
    await digitar(1, '2 comprimidos de 50mg');
    await tocar(texto('Adicionar mais um horário'));
    await esperar(find.byIcon(Icons.close));
    await tocar(find.byIcon(Icons.close).last);
    await tocar(texto('Salvar'));
    await esperar(texto('Losartana Teste • 2 comprimidos de 50mg'));
    remedio = await rede(() =>
        db.from('medicamentos').select('*, horarios(*)').eq('id', remedioId).single());
    expect(remedio['dose_texto'], '2 comprimidos de 50mg');
    expect((remedio['horarios'] as List).length, 2);
    passo('Editar remédio -> dose atualizada no banco, horários mantidos');

    // =============== 5. RECEITA / EXAME (RF05) ===============
    Future<void> novoDocumento(String nome, {bool exame = false}) async {
      await tocar(texto('Adicionar receita ou exame'));
      await esperar(texto('Receita ou exame'));
      if (exame) await tocar(texto('Exame'));
      await digitar(0, nome);
      await digitar(1, 'Laboratório Teste');
      await tocar(find.byIcon(Icons.calendar_today));
      await esperar(texto('OK'));
      await tocar(texto('OK'));
      await tocar(texto('Galeria'));
      await esperar(find.byType(Image));
      await tocar(texto('Salvar'));
      await sumir(texto('Receita ou exame')); // formulário fechou = salvou
      await esperar(texto(nome));
    }

    await novoDocumento('Receita Teste');
    await novoDocumento('Exame de Sangue Teste', exame: true);
    var docs = await rede(() => db.from('documentos').select().eq('idoso_id', idosoId));
    expect(docs.length, 2);
    expect(docs.map((d) => d['tipo']).toSet(), {'receita', 'exame'});
    expect(docs.every((d) => d['arquivo_path'] != null), isTrue);
    arquivos = await rede(() => db.storage.from('arquivos').list(path: idosoId));
    expect(arquivos.length, 3);
    passo('Adicionar receita e exame (data + foto) -> "documentos" + fotos no Storage');

    // remover a receita
    await tocar(find.byIcon(Icons.delete_outline).first);
    await esperar(texto('Remover documento?'));
    await tocar(texto('Remover'));
    await sumir(texto('Receita Teste'));
    docs = await rede(() => db.from('documentos').select().eq('idoso_id', idosoId));
    expect(docs.length, 1);
    arquivos = await rede(() => db.storage.from('arquivos').list(path: idosoId));
    expect(arquivos.length, 2);
    passo('Remover documento -> apagou do banco e a foto do Storage');

    // =============== 6. WHATSAPP (RF02) ===============
    await tocar(texto('Enviar link pelo WhatsApp'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    expect(navegador.abertos, isNotEmpty);
    final link = Uri.decodeFull(navegador.abertos.last);
    expect(link, startsWith('https://wa.me/5543999990000'));
    expect(link, contains('/#/entrar/${idoso['codigo_acesso']}'));
    passo('Enviar link pelo WhatsApp -> abre wa.me com o número e o link /#/entrar/CÓDIGO');

    // =============== 7. CONFIGURAÇÕES ===============
    await tocar(find.byTooltip('Configurações'));
    await esperar(texto('Rotina da Sra. Teste'));
    for (final chave in ['Remédio não marcado', 'Resumo do dia', 'Som do lembrete', 'Vibração']) {
      await tocar(texto(chave));
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 700)));
      await t.pump();
    }
    await tocar(texto('Tamanho da letra'));
    await tocar(texto('Muito grande'));
    await esperar(texto('Muito grande'));
    await tocar(texto('Horários das refeições'));
    await esperar(texto('Café da manhã'));
    await tocar(texto('Salvar'));
    await t.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await t.pump();
    var conf = await rede(() => db.from('idosos').select().eq('id', idosoId).single());
    expect(conf['aviso_atraso'], isFalse);
    expect(conf['resumo_diario'], isFalse);
    expect(conf['som'], isFalse);
    expect(conf['vibracao'], isFalse);
    expect(conf['tamanho_letra'], 'muito_grande');
    passo('Configurações: 4 chaves + tamanho da letra + horários -> gravados em "idosos"');

    // religa som e vibração para testar o RF07 depois
    await tocar(texto('Som do lembrete'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 700)));
    await tocar(texto('Vibração'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 700)));
    await t.pump();

    final codigoAntigo = conf['codigo_acesso'] as String;
    await tocar(texto('Acesso e aparelhos'));
    await esperar(contem('Celulares conectados: 0'));
    await tocar(texto('Gerar novo código'));
    await esperar(texto('Gerar novo código?'));
    await tocar(texto('Gerar'));
    await esperar(contem('Novo código:'));
    conf = await rede(() => db.from('idosos').select().eq('id', idosoId).single());
    final codigoIdoso = conf['codigo_acesso'] as String;
    expect(codigoIdoso, isNot(codigoAntigo));
    expect(conf['som'], isTrue);
    expect(conf['vibracao'], isTrue);
    passo('Gerar novo código -> código trocado no banco');

    // vincular a uma pessoa existente (Sra. Maria) e voltar
    await tocar(texto('+ Adicionar pessoa'));
    await esperar(texto('Adicionar pessoa'));
    await tocar(texto('Adicionar usuário existente'));
    await esperar(find.byType(AlertDialog));
    await t.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), '20262026');
    await tocar(texto('Adicionar'));
    await esperar(contem('Painel da Sra. Maria'));
    final acessos = await rede(() => db.from('acessos').select('idoso_id').eq('user_id', cuidadorId));
    expect(acessos.length, 2);
    passo('Adicionar usuário existente (20262026) -> vínculo gravado em "acessos", abre painel da Sra. Maria');

    await tocar(contem('Painel da Sra. Maria'));
    await tocar(texto('Sra. Teste $sobrenome'));
    await esperar(texto('Painel da Sra. Teste'));
    passo('Trocar de pessoa pelo menu do painel');

    // sair
    await tocar(find.byTooltip('Configurações'));
    await tocar(texto('Sair desta conta'));
    await esperar(texto('TENHO UM CÓDIGO'));
    expect(db.auth.currentUser, isNull);
    passo('Sair desta conta -> volta à tela inicial, sessão encerrada');

    // =============== 8. IDOSO (RF02, RF01, RF06, RF07, RF05) ===============
    await tocar(texto('TENHO UM CÓDIGO'));
    await esperar(texto('Digite o seu código'));
    await digitar(0, '123');
    await tocar(texto('ENTRAR'));
    await esperar(texto('O código tem 6 números.'));
    await digitar(0, '000001');
    await tocar(texto('ENTRAR'));
    await esperar(texto('Código não encontrado.'));
    passo('Código do idoso curto/errado -> avisos corretos');
    anonimos.add(db.auth.currentUser!.id);

    await digitar(0, codigoIdoso);
    await tocar(texto('ENTRAR'));
    await esperar(contem(', Sra. Teste!'));
    await esperar(contem('0 de 2'));
    expect(db.auth.currentUser!.isAnonymous, isTrue);
    passo('Idoso entra só com o código, sem senha (sessão anônima) -> "Hoje: 0 de 2 tomados"');

    // RLS: idoso não pode cadastrar remédio
    Object? erroRls;
    await rede(() async {
      try {
        await db.from('medicamentos').insert({'idoso_id': idosoId, 'nome': 'x', 'dose_texto': 'x'});
      } catch (e) {
        erroRls = e;
      }
    });
    expect(erroRls, isA<PostgrestException>());
    passo('Segurança: idoso NÃO consegue cadastrar remédio (RLS bloqueou)');

    // abre o compartimento do almoço
    await tocar(find.byIcon(Icons.restaurant).last);
    await esperar(texto('ALMOÇO'));
    await esperar(texto('JÁ TOMEI ESTE REMÉDIO'));
    plataforma.clear();
    await tocar(texto('JÁ TOMEI ESTE REMÉDIO'));
    await esperar(contem('Pronto! Anotado: Losartana Teste'));
    expect(plataforma, containsAll(['HapticFeedback.vibrate', 'SystemSound.play']));
    passo('JÁ TOMEI -> mensagem "Pronto! Anotado", vibração e som (RF01 + RF07)');
    await tocar(texto('OK'));
    await esperar(contem('Tomado às'));
    final horarioAlmoco = horarios.firstWhere((h) => h['turno'] == 'almoco')['id'];
    var doses = await rede(() => db.from('doses').select().eq('horario_id', horarioAlmoco));
    expect(doses.length, 1);
    passo('Dose gravada em "doses"');

    await tocar(texto('Marquei por engano.'));
    await esperar(texto('JÁ TOMEI ESTE REMÉDIO'));
    doses = await rede(() => db.from('doses').select().eq('horario_id', horarioAlmoco));
    expect(doses, isEmpty);
    passo('"Marquei por engano." -> dose apagada do banco');

    await tocar(texto('JÁ TOMEI ESTE REMÉDIO'));
    await tocar(texto('OK'));
    await esperar(contem('Tomado às'));

    await tocar(texto('Ver foto'));
    await esperar(texto('Use dois dedos para aumentar'));
    await tocar(texto('VOLTAR'));
    await esperar(texto('Marquei por engano.'));
    passo('"Ver foto" abre a foto do remédio e VOLTAR retorna');

    await tocar(texto('VOLTAR'));
    await esperar(contem('1 de 2'));
    passo('Volta para a caixinha -> "Hoje: 1 de 2 tomados" (RF06)');

    await tocar(texto('CONSULTA DE HOJE'));
    await esperar(texto('Exame de Sangue Teste'));
    await tocar(texto('Exame de Sangue Teste'));
    await esperar(texto('Use dois dedos para aumentar'));
    await tocar(texto('VOLTAR'));
    await tocar(texto('VOLTAR'));
    await esperar(texto('TOMAR REMÉDIO'));
    passo('CONSULTA DE HOJE lista o exame e abre a foto em tela cheia');

    await tocar(texto('TOMAR REMÉDIO'));
    await tocar(texto('VOLTAR'));
    await esperar(texto('TOMAR REMÉDIO'));
    passo('Botão TOMAR REMÉDIO abre o turno atual');

    await tocar(find.byTooltip('Sair deste celular'));
    await tocar(texto('Ficar'));
    await tocar(find.byTooltip('Sair deste celular'));
    await tocar(texto('Sair'));
    await esperar(texto('TENHO UM CÓDIGO'));
    passo('Engrenagem do idoso: "Ficar" e "Sair" funcionam');

    // =============== 9. CUIDADOR DE NOVO + TEMPO REAL ===============
    await tocar(texto('Sou cuidador / familiar'));
    await digitar(0, email);
    await digitar(1, 'senha-errada');
    await tocar(texto('Entrar'));
    await esperar(texto('E-mail ou senha incorretos.'));
    passo('Senha errada -> "E-mail ou senha incorretos."');
    await digitar(1, senha);
    await tocar(texto('Entrar'));
    await esperar(contem('Painel da Sra.'));
    if (find.text('Painel da Sra. Teste').evaluate().isEmpty) {
      await tocar(contem('Painel da Sra.'));
      await tocar(texto('Sra. Teste $sobrenome'));
      await esperar(texto('Painel da Sra. Teste'));
    }
    await esperar(contem('Tomado às'));
    expect(contem('Tomado às'), findsOneWidget);
    passo('Login do cuidador -> painel mostra a dose que o idoso marcou');

    // outro "celular" do idoso marca a dose da noite; o painel deve atualizar sozinho
    final horarioNoite = horarios.firstWhere((h) => h['turno'] == 'noite')['id'];
    final celular2 = SupabaseClient(Config.supabaseUrl, Config.supabaseAnonKey);
    await rede(() async {
      await celular2.auth.signInAnonymously();
      anonimos.add(celular2.auth.currentUser!.id);
      await celular2.rpc('entrar_como_idoso', params: {'p_codigo': codigoIdoso});
      await celular2.from('doses').insert({'horario_id': horarioNoite});
    });
    final fimRt = DateTime.now().add(const Duration(seconds: 20));
    while (find.textContaining('Tomado às').evaluate().length < 2) {
      if (DateTime.now().isAfter(fimRt)) throw TestFailure('Painel não atualizou em tempo real');
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 150)));
      await t.pump(const Duration(milliseconds: 50));
    }
    passo('Tempo real: dose marcada em outro celular aparece no painel sem atualizar');
    await rede(() => celular2.dispose());

    // remover o remédio (desativa, mantém histórico)
    await tocar(find.byIcon(Icons.edit));
    await tocar(texto('Remover remédio'));
    await esperar(texto('Remover Losartana Teste?'));
    await tocar(texto('Remover'));
    await sumir(texto('Losartana Teste • 2 comprimidos de 50mg'));
    remedio = await rede(() => db.from('medicamentos').select().eq('id', remedioId).single());
    expect(remedio['ativo'], isFalse);
    doses = await rede(() => db.from('doses').select().inFilter('horario_id', [horarioAlmoco, horarioNoite]));
    expect(doses.length, 2);
    passo('Remover remédio -> ativo=false e histórico de doses mantido');

    // =============== LIMPEZA (arquivos do Storage) ===============
    await t.pumpWidget(const SizedBox());
    await rede(() async {
      final l = await db.storage.from('arquivos').list(path: idosoId);
      if (l.isNotEmpty) {
        await db.storage.from('arquivos').remove(l.map((f) => '$idosoId/${f.name}').toList());
      }
      await db.auth.signOut();
      await db.removeAllChannels();
      db.realtime.disconnect();
    });
    // timers internos do cliente (renovação de sessão, reconexão) terminam aqui
    db.auth.stopAutoRefresh();
    await t.pump(const Duration(minutes: 1));

    // ignore: avoid_print
    print('\n===== ${_resultado.length} verificações OK =====\n'
        'LIMPEZA_SQL idoso=$idosoId cuidador=$cuidadorId anonimos=${anonimos.join(',')}');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
