import 'package:flutter/material.dart';

// ---------------- Turno (Sol / Prato / Lua) ----------------
enum Turno { manha, almoco, noite }

extension TurnoInfo on Turno {
  String get nome => switch (this) {
        Turno.manha => 'Manhã',
        Turno.almoco => 'Almoço',
        Turno.noite => 'Noite',
      };

  /// Como aparece para o idoso: "Tomar no almoço".
  String get textoTomar => switch (this) {
        Turno.manha => 'Tomar com o café da manhã',
        Turno.almoco => 'Tomar no almoço',
        Turno.noite => 'Tomar no jantar',
      };

  /// Lista do painel: "Manhã (com o café da manhã)".
  String get textoPainel => switch (this) {
        Turno.manha => 'Manhã (com o café da manhã)',
        Turno.almoco => 'Almoço (no almoço)',
        Turno.noite => 'Noite (no jantar)',
      };

  /// Usado na faixa de status: "Falta tomar o remédio do almoço".
  String get doTurno => switch (this) {
        Turno.manha => 'da manhã',
        Turno.almoco => 'do almoço',
        Turno.noite => 'da noite',
      };

  /// Horários das refeições: "Café da manhã • das 05:00 às 10:59".
  String get refeicao => switch (this) {
        Turno.manha => 'Café da manhã',
        Turno.almoco => 'Almoço',
        Turno.noite => 'Jantar',
      };

  String get faixa => switch (this) {
        Turno.manha => 'das 05:00 às 10:59',
        Turno.almoco => 'das 11:00 às 15:59',
        Turno.noite => 'das 16:00 às 04:59',
      };

  String get valorBanco => name; // 'manha' | 'almoco' | 'noite'
}

Turno turnoDoBanco(String v) =>
    Turno.values.firstWhere((t) => t.name == v, orElse: () => Turno.manha);

/// Turno pela hora, com as faixas do Figma (Manhã 05–10:59, Almoço 11–15:59, Noite 16–04:59).
Turno turnoPelaHora(TimeOfDay h) {
  if (h.hour < 5) return Turno.noite;
  if (h.hour < 11) return Turno.manha;
  if (h.hour < 16) return Turno.almoco;
  return Turno.noite;
}

// ---------------- Conversões de hora ----------------
TimeOfDay horaDoBanco(String v) {
  final p = v.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

String horaParaBanco(TimeOfDay h) =>
    '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

String horaTexto(TimeOfDay h) => horaParaBanco(h);

/// "8:05" (como no Figma: "Tomado às 8:05.").
String horaCurta(DateTime d) => '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

int minutosDoDia(TimeOfDay h) => h.hour * 60 + h.minute;

// ---------------- Idoso (pessoa acompanhada) ----------------
class Idoso {
  final String id;
  final String nome;
  final String? sobrenome;
  final String tratamento; // nenhum | senhor | senhora
  final String? whatsapp;
  final String codigoAcesso;
  final DateTime codigoExpiraEm;
  final String codigoCuidador;
  final TimeOfDay horaCafe;
  final TimeOfDay horaAlmoco;
  final TimeOfDay horaJantar;
  final String tamanhoLetra; // normal | grande | muito_grande
  final bool som;
  final bool vibracao;
  final bool repetirLembrete;
  final bool avisoAtraso;
  final int avisoMinutos; // 30 | 60 | 120
  final String avisoCanal; // whatsapp | app | ambos
  final bool resumoDiario;

  Idoso({
    required this.id,
    required this.nome,
    this.sobrenome,
    required this.tratamento,
    this.whatsapp,
    required this.codigoAcesso,
    required this.codigoExpiraEm,
    required this.codigoCuidador,
    required this.horaCafe,
    required this.horaAlmoco,
    required this.horaJantar,
    required this.tamanhoLetra,
    required this.som,
    required this.vibracao,
    required this.repetirLembrete,
    required this.avisoAtraso,
    required this.avisoMinutos,
    required this.avisoCanal,
    required this.resumoDiario,
  });

  factory Idoso.fromMap(Map<String, dynamic> m) => Idoso(
        id: m['id'],
        nome: m['nome'],
        sobrenome: m['sobrenome'],
        tratamento: m['tratamento'] ?? 'nenhum',
        whatsapp: m['whatsapp'],
        codigoAcesso: m['codigo_acesso'],
        codigoExpiraEm: m['codigo_expira_em'] == null
            ? DateTime.now().add(const Duration(minutes: 10))
            : DateTime.parse(m['codigo_expira_em']).toLocal(),
        codigoCuidador: m['codigo_cuidador'],
        horaCafe: horaDoBanco(m['hora_cafe']),
        horaAlmoco: horaDoBanco(m['hora_almoco']),
        horaJantar: horaDoBanco(m['hora_jantar']),
        tamanhoLetra: m['tamanho_letra'] ?? 'grande',
        som: m['som'] ?? true,
        vibracao: m['vibracao'] ?? true,
        repetirLembrete: m['repetir_lembrete'] ?? false,
        avisoAtraso: m['aviso_atraso'] ?? true,
        avisoMinutos: m['aviso_minutos'] ?? 60,
        avisoCanal: m['aviso_canal'] ?? 'whatsapp',
        resumoDiario: m['resumo_diario'] ?? true,
      );

  String get primeiroNome => nome.trim().split(' ').first;

  /// "Sra. Maria", "Sr. José" ou só "Maria".
  String get nomeTratamento => switch (tratamento) {
        'senhora' => 'Sra. $primeiroNome',
        'senhor' => 'Sr. $primeiroNome',
        _ => primeiroNome,
      };

  /// "Sra. Maria Judite" (lista de pessoas nas configurações).
  String get nomeCompletoTratamento => switch (tratamento) {
        'senhora' => 'Sra. $nome',
        'senhor' => 'Sr. $nome',
        _ => nome,
      };

  /// "Ela" / "Ele" para textos do cuidador.
  String get pronome => tratamento == 'senhor' ? 'Ele' : 'Ela';

  /// "Painel da Sra. Maria" / "Painel do Sr. José".
  String get daDo => tratamento == 'senhor' ? 'do' : 'da';

  /// "o painel dela" / "o painel dele".
  String get delaDele => tratamento == 'senhor' ? 'dele' : 'dela';

  String get tamanhoLetraTexto => switch (tamanhoLetra) {
        'normal' => 'Normal',
        'muito_grande' => 'Maior',
        _ => 'Grande',
      };

  double get escalaLetra => switch (tamanhoLetra) {
        'normal' => 0.9,
        'muito_grande' => 1.2,
        _ => 1.0,
      };

  /// "Depois de 1 hora • pelo WhatsApp".
  String get resumoAviso {
    final tempo = switch (avisoMinutos) { 30 => '30 min', 120 => '2 horas', _ => '1 hora' };
    final canal = switch (avisoCanal) { 'app' => 'no app', 'ambos' => 'WhatsApp e app', _ => 'pelo WhatsApp' };
    return 'Depois de $tempo • $canal';
  }

  bool get codigoValido => codigoExpiraEm.isAfter(DateTime.now());

  TimeOfDay horaDoTurno(Turno t) => switch (t) {
        Turno.manha => horaCafe,
        Turno.almoco => horaAlmoco,
        Turno.noite => horaJantar,
      };

  /// Turno atual (faixas fixas do Figma).
  Turno turnoAgora(DateTime agora) =>
      turnoPelaHora(TimeOfDay(hour: agora.hour, minute: agora.minute));
}

// ---------------- Dose de hoje (vem da função doses_de_hoje) ----------------
class DoseHoje {
  final String horarioId;
  final String medicamentoId;
  final String nome;
  final String doseTexto;
  final String? finalidade;
  final String? fotoPath;
  final String? formato;
  final String? cor;
  final String? cor2;
  final TimeOfDay hora;
  final Turno turno;
  final String? doseId;
  final DateTime? tomadoEm;
  final String status; // tomado | atrasado | agora | futuro

  DoseHoje({
    required this.horarioId,
    required this.medicamentoId,
    required this.nome,
    required this.doseTexto,
    this.finalidade,
    this.fotoPath,
    this.formato,
    this.cor,
    this.cor2,
    required this.hora,
    required this.turno,
    this.doseId,
    this.tomadoEm,
    required this.status,
  });

  factory DoseHoje.fromMap(Map<String, dynamic> m) => DoseHoje(
        horarioId: m['horario_id'],
        medicamentoId: m['medicamento_id'],
        nome: m['nome'],
        doseTexto: m['dose_texto'],
        finalidade: m['finalidade'],
        fotoPath: m['foto_path'],
        formato: m['formato'],
        cor: m['cor'],
        cor2: m['cor2'],
        hora: horaDoBanco(m['hora']),
        turno: turnoDoBanco(m['turno']),
        doseId: m['dose_id'],
        tomadoEm: m['tomado_em'] == null ? null : DateTime.parse(m['tomado_em']).toLocal(),
        status: m['status'],
      );

  bool get tomado => doseId != null;
}

// ---------------- Medicamento + horários ----------------
class Horario {
  final String? id;
  TimeOfDay hora;
  Turno turno;
  Horario({this.id, required this.hora, required this.turno});

  factory Horario.fromMap(Map<String, dynamic> m) => Horario(
        id: m['id'],
        hora: horaDoBanco(m['hora']),
        turno: turnoDoBanco(m['turno']),
      );
}

class Medicamento {
  final String? id;
  final String idosoId;
  final String nome;
  final String doseTexto;
  final String? finalidade;
  final String? fotoPath;
  final String? formato;
  final String? cor;
  final String? cor2;
  final List<Horario> horarios;

  Medicamento({
    this.id,
    required this.idosoId,
    required this.nome,
    required this.doseTexto,
    this.finalidade,
    this.fotoPath,
    this.formato,
    this.cor,
    this.cor2,
    required this.horarios,
  });

  factory Medicamento.fromMap(Map<String, dynamic> m) {
    final hs = ((m['horarios'] as List?) ?? [])
        .map((h) => Horario.fromMap(h as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => minutosDoDia(a.hora).compareTo(minutosDoDia(b.hora)));
    return Medicamento(
      id: m['id'],
      idosoId: m['idoso_id'],
      nome: m['nome'],
      doseTexto: m['dose_texto'],
      finalidade: m['finalidade'],
      fotoPath: m['foto_path'],
      formato: m['formato'],
      cor: m['cor'],
      cor2: m['cor2'],
      horarios: hs,
    );
  }
}

// ---------------- Documento (receita / exame) ----------------
class Documento {
  final String id;
  final String tipo; // receita | exame
  final String titulo;
  final String? origem; // especialidade ("Clínico Geral") ou "Laboratório"
  final DateTime? data;
  final String? descricao;
  final String? arquivoPath;

  Documento({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.origem,
    this.data,
    this.descricao,
    this.arquivoPath,
  });

  factory Documento.fromMap(Map<String, dynamic> m) => Documento(
        id: m['id'],
        tipo: m['tipo'],
        titulo: m['titulo'],
        origem: m['origem'],
        data: m['data'] == null ? null : DateTime.parse(m['data']),
        descricao: m['descricao'],
        arquivoPath: m['arquivo_path'],
      );

  /// O que foi digitado em "Especialidade" no cadastro.
  String get especialidade {
    if (tipo == 'exame') return titulo;
    return origem ?? titulo.replaceFirst(RegExp(r'^Receita d[oa] '), '');
  }
}

/// Título do documento a partir da especialidade (como no Figma):
/// receita "Clínico Geral" -> "Receita do Clínico Geral"; exame -> o próprio nome.
String tituloDocumento(String tipo, String especialidade) =>
    tipo == 'receita' ? 'Receita do ${especialidade.trim()}' : especialidade.trim();

// ---------------- Cuidador (perfil) e pessoas com acesso ----------------
class Cuidador {
  final String nome;
  final String? sobrenome;
  final String? whatsapp;
  final bool autorizaWhatsapp;
  Cuidador({required this.nome, this.sobrenome, this.whatsapp, required this.autorizaWhatsapp});

  factory Cuidador.fromMap(Map<String, dynamic> m) => Cuidador(
        nome: m['nome'],
        sobrenome: m['sobrenome'],
        whatsapp: m['whatsapp'],
        autorizaWhatsapp: m['autoriza_whatsapp'] ?? true,
      );
}

/// Uma linha de "acessos": um celular conectado (idoso) ou um cuidador.
class Pessoa {
  final String userId;
  final String papel; // idoso | cuidador
  final String? aparelho;
  final DateTime ultimoUso;
  final bool recebeAvisos;
  final String? nome;
  final String? whatsapp;
  final bool autorizaWhatsapp;
  final bool souEu;

  Pessoa({
    required this.userId,
    required this.papel,
    this.aparelho,
    required this.ultimoUso,
    required this.recebeAvisos,
    this.nome,
    this.whatsapp,
    required this.autorizaWhatsapp,
    required this.souEu,
  });

  factory Pessoa.fromMap(Map<String, dynamic> m) => Pessoa(
        userId: m['user_id'],
        papel: m['papel'],
        aparelho: m['aparelho'],
        ultimoUso: DateTime.parse(m['ultimo_uso']).toLocal(),
        recebeAvisos: m['recebe_avisos'] ?? true,
        nome: m['nome'],
        whatsapp: m['whatsapp'],
        autorizaWhatsapp: m['autoriza_whatsapp'] ?? false,
        souEu: m['sou_eu'] ?? false,
      );
}

/// "(43) 99999-9999" a partir de "5543999999999".
String telefoneTexto(String? numero) {
  final n = (numero ?? '').replaceAll(RegExp(r'\D'), '');
  final local = n.startsWith('55') && n.length > 11 ? n.substring(2) : n;
  if (local.length < 10) return local;
  final ddd = local.substring(0, 2);
  final resto = local.substring(2);
  final corte = resto.length - 4;
  return '($ddd) ${resto.substring(0, corte)}-${resto.substring(corte)}';
}

/// "usado hoje às 12:22" / "Usado há 3 dias".
String quandoUsado(DateTime d, DateTime agora) {
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(d.year, d.month, d.day);
  final dias = hoje.difference(dia).inDays;
  if (dias <= 0) return 'usado hoje às ${horaTexto(TimeOfDay.fromDateTime(d))}';
  if (dias == 1) return 'usado ontem';
  return 'usado há $dias dias';
}
