
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modelos.dart';

/// Toda a comunicação com o Supabase fica aqui.
/// As telas só chamam estes métodos (fica fácil trocar o backend depois).
class Repo {
  static SupabaseClient get _db => Supabase.instance.client;

  static User? get usuario => _db.auth.currentUser;
  static bool get logado => usuario != null;

  // ======================= AUTENTICAÇÃO =======================

  /// Idoso: entra só com o código de 6 dígitos (sessão anônima, sem senha).
  static Future<String> entrarComoIdoso(String codigo) async {
    if (!logado) {
      await _db.auth.signInAnonymously();
    }
    final id = await _db.rpc('entrar_como_idoso',
        params: {'p_codigo': codigo, 'p_aparelho': aparelhoAtual()});
    return id as String;
  }

  /// Nome do aparelho para a lista "Celulares conectados".
  static String aparelhoAtual() {
    if (kIsWeb) return 'Navegador';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iPhone',
      _ => 'Computador',
    };
  }

  /// Avisa que este aparelho está usando o app (lista de aparelhos).
  static Future<void> registrarUso(String idosoId) async {
    try {
      await _db.rpc('registrar_uso', params: {'p_idoso': idosoId, 'p_aparelho': aparelhoAtual()});
    } catch (_) {/* não atrapalha o uso se falhar */}
  }

  static Future<void> loginCuidador(String email, String senha) =>
      _db.auth.signInWithPassword(email: email.trim(), password: senha);

  static Future<void> cadastrarCuidador(String email, String senha) async {
    final r = await _db.auth.signUp(email: email.trim(), password: senha);
    if (r.session == null) {
      throw Exception(
          'Conta criada. Confirme o e-mail que enviamos e depois faça login.');
    }
  }

  static Future<void> sair() => _db.auth.signOut();

  /// Descobre o papel do usuário logado: 'cuidador', 'idoso' ou null.
  static Future<({String? papel, String? idosoId})> meuPapel() async {
    if (!logado) return (papel: null, idosoId: null);
    final linhas = await _db
        .from('acessos')
        .select('idoso_id, papel')
        .eq('user_id', usuario!.id);
    if (linhas.isEmpty) {
      // usuário com e-mail e sem pessoas cadastradas = cuidador novo
      final anonimo = usuario!.isAnonymous;
      return (papel: anonimo ? null : 'cuidador', idosoId: null);
    }
    final cuidador = linhas.where((l) => l['papel'] == 'cuidador').toList();
    if (cuidador.isNotEmpty) {
      return (papel: 'cuidador', idosoId: cuidador.first['idoso_id'] as String);
    }
    return (papel: 'idoso', idosoId: linhas.first['idoso_id'] as String);
  }

  // ======================= CUIDADOR =======================

  static Future<Cuidador?> meuPerfil() async {
    final m = await _db.from('cuidadores').select().eq('user_id', usuario!.id).maybeSingle();
    return m == null ? null : Cuidador.fromMap(m);
  }

  static Future<void> salvarPerfil(
      {required String nome, String? sobrenome, String? whatsapp}) async {
    await _db.from('cuidadores').upsert({
      'user_id': usuario!.id,
      'nome': nome.trim(),
      'sobrenome': (sobrenome ?? '').trim().isEmpty ? null : sobrenome!.trim(),
      'whatsapp': (whatsapp ?? '').isEmpty ? null : whatsapp,
    });
  }

  static Future<void> definirAutorizaWhatsapp(bool valor) =>
      _db.from('cuidadores').update({'autoriza_whatsapp': valor}).eq('user_id', usuario!.id);

  /// Celulares do idoso e cuidadores com acesso (só quem cuida vê).
  static Future<List<Pessoa>> pessoas(String idosoId) async {
    final l = await _db.rpc('pessoas_do_idoso', params: {'p_idoso': idosoId});
    return (l as List).map((e) => Pessoa.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<void> definirRecebeAvisos(String idosoId, String userId, bool valor) =>
      _db.rpc('definir_recebe_avisos', params: {'p_idoso': idosoId, 'p_user': userId, 'p_valor': valor});

  /// "Toque em um celular para desconectá-lo."
  static Future<void> desconectar(String idosoId, String userId) =>
      _db.from('acessos').delete().eq('idoso_id', idosoId).eq('user_id', userId);

  // ======================= IDOSOS =======================

  static Future<Idoso> buscarIdoso(String id) async {
    final m = await _db.from('idosos').select().eq('id', id).single();
    return Idoso.fromMap(m);
  }

  static Future<List<Idoso>> idososDoCuidador() async {
    final linhas = await _db
        .from('acessos')
        .select('idosos(*)')
        .eq('user_id', usuario!.id)
        .eq('papel', 'cuidador');
    return linhas
        .where((l) => l['idosos'] != null)
        .map((l) => Idoso.fromMap(l['idosos'] as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  static Future<Idoso> criarIdoso({
    required String nome,
    String? sobrenome,
    required String tratamento,
    String? whatsapp,
  }) async {
    final m = await _db.rpc('criar_idoso', params: {
      'p_nome': nome.trim(),
      'p_sobrenome': sobrenome?.trim(),
      'p_tratamento': tratamento,
      'p_whatsapp': whatsapp?.replaceAll(RegExp(r'\D'), ''),
    });
    return Idoso.fromMap(m as Map<String, dynamic>);
  }

  static Future<String> vincularCuidador(String codigo) async {
    final id =
        await _db.rpc('vincular_cuidador', params: {'p_codigo': codigo.trim()});
    return id as String;
  }

  static Future<void> atualizarIdoso(String id, Map<String, dynamic> dados) =>
      _db.from('idosos').update(dados).eq('id', id);

  static Future<void> atualizarRefeicoes(
          String idosoId, TimeOfDay cafe, TimeOfDay almoco, TimeOfDay jantar) =>
      _db.rpc('atualizar_refeicoes', params: {
        'p_idoso': idosoId,
        'p_cafe': horaParaBanco(cafe),
        'p_almoco': horaParaBanco(almoco),
        'p_jantar': horaParaBanco(jantar),
      });

  /// Privacidade: apaga a pessoa e tudo dela (fotos primeiro, pelo Storage).
  static Future<void> apagarTudo(String idosoId) async {
    final arquivos = await _db.storage.from('arquivos').list(path: idosoId);
    if (arquivos.isNotEmpty) {
      await _db.storage.from('arquivos').remove(arquivos.map((f) => '$idosoId/${f.name}').toList());
    }
    await _db.rpc('apagar_idoso', params: {'p_idoso': idosoId});
  }

  /// Privacidade: "Baixar uma cópia dos dados".
  static Future<Map<String, dynamic>> exportarDados(String idosoId) async {
    final idoso = await _db.from('idosos').select().eq('id', idosoId).single();
    final remedios = await _db.from('medicamentos').select('*, horarios(*)').eq('idoso_id', idosoId);
    final horarioIds = [
      for (final m in remedios)
        for (final h in (m['horarios'] as List)) h['id'],
    ];
    final doses = horarioIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db.from('doses').select().inFilter('horario_id', horarioIds).order('data');
    final docs = await _db.from('documentos').select().eq('idoso_id', idosoId);
    return {
      'exportado_em': DateTime.now().toIso8601String(),
      'pessoa': idoso,
      'remedios': remedios,
      'doses': doses,
      'receitas_e_exames': docs,
    };
  }

  static Future<String> novoCodigoIdoso(String id) async {
    final c = await _db.rpc('novo_codigo_idoso', params: {'p_idoso': id});
    return c as String;
  }

  /// Quantos celulares do idoso estão conectados.
  static Future<int> aparelhosDoIdoso(String idosoId) async {
    final l = await _db
        .from('acessos')
        .select('user_id')
        .eq('idoso_id', idosoId)
        .eq('papel', 'idoso');
    return l.length;
  }

  // ======================= DOSES =======================

  static Future<List<DoseHoje>> dosesDeHoje(String idosoId) async {
    final l = await _db.rpc('doses_de_hoje', params: {'p_idoso': idosoId});
    return (l as List)
        .map((e) => DoseHoje.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// "Já tomei" — retorna o horário registrado.
  static Future<DateTime> confirmarDose(String horarioId) async {
    final m = await _db
        .from('doses')
        .insert({'horario_id': horarioId})
        .select('tomado_em')
        .single();
    return DateTime.parse(m['tomado_em']).toLocal();
  }

  /// "Marquei por engano".
  static Future<void> desfazerDose(String doseId) =>
      _db.from('doses').delete().eq('id', doseId);

  /// Avisa quando alguma dose muda (painel do cuidador em tempo real).
  static RealtimeChannel ouvirDoses(VoidCallback aoMudar) {
    return _db
        .channel('doses-${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'doses',
          callback: (_) => aoMudar(),
        )
        .subscribe();
  }

  static Future<void> pararDeOuvir(RealtimeChannel canal) =>
      _db.removeChannel(canal);

  // ======================= MEDICAMENTOS =======================

  static Future<List<Medicamento>> medicamentos(String idosoId) async {
    final l = await _db
        .from('medicamentos')
        .select('*, horarios(*)')
        .eq('idoso_id', idosoId)
        .eq('ativo', true)
        .order('nome');
    return l.map((m) => Medicamento.fromMap(m)).toList();
  }

  static Future<void> salvarMedicamento(Medicamento m) async {
    final dados = {
      'idoso_id': m.idosoId,
      'nome': m.nome.trim(),
      'dose_texto': m.doseTexto.trim(),
      'finalidade': (m.finalidade ?? '').trim().isEmpty ? null : m.finalidade!.trim(),
      'foto_path': m.fotoPath,
      'formato': m.formato,
      'cor': m.cor,
      'cor2': m.cor2,
    };

    String id;
    if (m.id == null) {
      final r = await _db.from('medicamentos').insert(dados).select('id').single();
      id = r['id'];
    } else {
      id = m.id!;
      await _db.from('medicamentos').update(dados).eq('id', id);
      // horários antigos saem e entram os novos (o histórico de doses de
      // horários removidos é apagado junto — aceitável no MVP)
      final manter = m.horarios.where((h) => h.id != null).map((h) => h.id!).toList();
      var del = _db.from('horarios').delete().eq('medicamento_id', id);
      if (manter.isNotEmpty) {
        del = del.not('id', 'in', '(${manter.join(',')})');
      }
      await del;
      for (final h in m.horarios.where((h) => h.id != null)) {
        await _db.from('horarios').update({
          'hora': horaParaBanco(h.hora),
          'turno': h.turno.valorBanco,
        }).eq('id', h.id!);
      }
    }

    final novos = m.horarios.where((h) => h.id == null).map((h) => {
          'medicamento_id': id,
          'hora': horaParaBanco(h.hora),
          'turno': h.turno.valorBanco,
        });
    if (novos.isNotEmpty) {
      await _db.from('horarios').insert(novos.toList());
    }
  }

  /// Não apaga de verdade: só desativa (mantém o histórico).
  static Future<void> removerMedicamento(String id) =>
      _db.from('medicamentos').update({'ativo': false}).eq('id', id);

  // ======================= DOCUMENTOS =======================

  static Future<List<Documento>> documentos(String idosoId) async {
    final l = await _db
        .from('documentos')
        .select()
        .eq('idoso_id', idosoId)
        .order('data', ascending: false);
    return l.map((d) => Documento.fromMap(d)).toList();
  }

  /// Novo (id == null) ou edição de receita/exame.
  static Future<void> salvarDocumento({
    String? id,
    required String idosoId,
    required String tipo,
    required String titulo,
    String? origem,
    DateTime? data,
    String? descricao,
    String? arquivoPath,
  }) async {
    final dados = {
      'idoso_id': idosoId,
      'tipo': tipo,
      'titulo': titulo.trim(),
      'origem': (origem ?? '').trim().isEmpty ? null : origem!.trim(),
      'data': data?.toIso8601String().substring(0, 10),
      'descricao': (descricao ?? '').trim().isEmpty ? null : descricao!.trim(),
      'arquivo_path': arquivoPath,
    };
    if (id == null) {
      await _db.from('documentos').insert(dados);
    } else {
      await _db.from('documentos').update(dados).eq('id', id);
    }
  }

  static Future<void> removerDocumento(Documento d) async {
    await _db.from('documentos').delete().eq('id', d.id);
    if (d.arquivoPath != null) {
      await _db.storage.from('arquivos').remove([d.arquivoPath!]);
    }
  }

  // ======================= ARQUIVOS (fotos) =======================

  /// Envia uma foto e devolve o caminho salvo (pasta = id do idoso).
  static Future<String> enviarFoto(
      String idosoId, Uint8List bytes, String extensao) async {
    final ext = extensao.toLowerCase().replaceAll('.', '');
    final caminho = '$idosoId/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _db.storage.from('arquivos').uploadBinary(
          caminho,
          bytes,
          fileOptions: FileOptions(contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}'),
        );
    return caminho;
  }

  /// Link temporário (1 hora) para mostrar a foto.
  static Future<String> linkDaFoto(String caminho) =>
      _db.storage.from('arquivos').createSignedUrl(caminho, 3600);
}

/// Mensagem amigável para mostrar ao usuário.
String mensagemDeErro(Object e) {
  if (e is PostgrestException) {
    // unique (horario_id, data): toque duplo ou outro celular já marcou
    if (e.code == '23505') return 'Este remédio já estava anotado hoje.';
    if (e.code == 'PGRST202' || e.code == '42703') {
      return 'O banco ainda não foi atualizado (migração 003_telas_figma.sql).';
    }
    return e.message;
  }
  if (e is AuthException) {
    if (e.message.contains('Invalid login')) return 'E-mail ou senha incorretos.';
    if (e.message.toLowerCase().contains('anonymous')) {
      return 'Login sem senha desativado no Supabase (ative "Anonymous sign-ins").';
    }
    return e.message;
  }
  return e.toString().replaceFirst('Exception: ', '');
}
