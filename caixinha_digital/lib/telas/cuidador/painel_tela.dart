import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../dados/modelos.dart';
import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import '../idoso/consulta_tela.dart' show iconeDocumento;
import 'configuracoes_tela.dart';
import 'documento_form_tela.dart';
import 'remedio_form_tela.dart';
import 'whatsapp.dart';

/// Cuidador / 10–12 Painel (RF03, RF04, RF05) — atualiza em tempo real.
class PainelTela extends StatefulWidget {
  final String idosoId;
  const PainelTela({super.key, required this.idosoId});

  @override
  State<PainelTela> createState() => _PainelTelaState();
}

class _PainelTelaState extends State<PainelTela> {
  late String _idosoId = widget.idosoId;
  List<Idoso> _pessoas = [];
  Idoso? _idoso;
  List<DoseHoje> _doses = [];
  List<Medicamento> _remedios = [];
  List<Documento> _docs = [];
  RealtimeChannel? _canal;
  Timer? _relogio;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
    Repo.registrarUso(_idosoId);
    _canal = Repo.ouvirDoses(_carregarDoses);
    _relogio = Timer.periodic(const Duration(minutes: 1), (_) => _carregarDoses());
  }

  @override
  void dispose() {
    _relogio?.cancel();
    if (_canal != null) Repo.pararDeOuvir(_canal!);
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final r = await Future.wait([
        Repo.idososDoCuidador(),
        Repo.buscarIdoso(_idosoId),
        Repo.dosesDeHoje(_idosoId),
        Repo.medicamentos(_idosoId),
        Repo.documentos(_idosoId),
      ]);
      if (!mounted) return;
      setState(() {
        _pessoas = r[0] as List<Idoso>;
        _idoso = r[1] as Idoso;
        _doses = r[2] as List<DoseHoje>;
        _remedios = r[3] as List<Medicamento>;
        _docs = r[4] as List<Documento>;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        mostrarErro(context, e);
      }
    }
  }

  Future<void> _carregarDoses() async {
    try {
      final d = await Repo.dosesDeHoje(_idosoId);
      if (mounted) setState(() => _doses = d);
    } catch (_) {}
  }

  void _trocarPessoa(String id) {
    setState(() {
      _idosoId = id;
      _carregando = true;
    });
    Repo.registrarUso(id);
    _carregar();
  }

  Future<void> _abrir(Widget tela) async {
    final r = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
    if (!mounted) return;
    if (r is String && r != _idosoId) {
      _trocarPessoa(r);
    } else {
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando || _idoso == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final i = _idoso!;
    final agora = DateTime.now();
    final semConfirmacao = i.avisoAtraso ? _doses.where((d) => d.status == 'atrasado').toList() : <DoseHoje>[];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregar,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 24), children: [
            // ---------- Cabeçalho com troca de pessoa e Configurações ----------
            Row(children: [
              Expanded(
                child: PopupMenuButton<String>(
                  onSelected: _trocarPessoa,
                  itemBuilder: (_) => [
                    for (final p in _pessoas)
                      PopupMenuItem(value: p.id, child: Text('${p.nomeTratamento} ${p.sobrenome ?? ''}')),
                  ],
                  child: Row(children: [
                    Flexible(
                      child: Text('Painel ${i.daDo} ${i.nomeTratamento}',
                          style: Estilos.cuidadorTitulo.copyWith(fontSize: 22)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_drop_down, size: 28, color: Cores.texto),
                  ]),
                ),
              ),
              BotaoEngrenagem(
                dica: 'Configurações',
                onTap: () => _abrir(ConfiguracoesTela(idoso: i, pessoas: _pessoas)),
              ),
            ]),
            Text(
                '${capitalizarPalavras(DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(agora))} • ${DateFormat.Hm().format(agora)}',
                style: Estilos.cuidadorCorpo.copyWith(fontSize: 14)),
            const SizedBox(height: 18),

            // ---------- Cuidador / 12 Aviso de omissão (RF04) ----------
            for (final d in semConfirmacao) _avisoOmissao(i, d, agora),

            // ---------- Doses de hoje ----------
            Secao(titulo: 'Doses de Hoje', filhos: [
              if (_doses.isEmpty) ...[
                Text('Não há medicações cadastradas ainda.', style: Estilos.cuidadorCorpo.copyWith(fontSize: 14)),
                const SizedBox(height: 16),
                Text('Adicione em “Remédios cadastrados”.', style: Estilos.cuidadorRotulo.copyWith(fontSize: 14)),
              ],
              for (final d in _doses)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    IconeTurno(d.turno, tamanho: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Text(d.nome, style: Estilos.cuidadorCorpo)),
                    _chipStatus(d),
                  ]),
                ),
            ]),

            // ---------- Remédios cadastrados ----------
            Secao(titulo: 'Remédios cadastrados', filhos: [
              for (final m in _remedios) _linhaRemedio(i, m),
              if (_remedios.isNotEmpty) const SizedBox(height: 8),
              Botao('Adicionar remédio', icone: Icons.add, onPressed: () => _abrir(RemedioFormTela(idoso: i))),
            ]),

            // ---------- Receitas e exames ----------
            Secao(
              titulo: 'Receitas e Exames',
              subtitulo: 'O que você adicionar aqui aparece na pasta “Consulta de Hoje” ${i.delaDele}.',
              filhos: [
                for (final d in _docs) _linhaDocumento(d),
                if (_docs.isNotEmpty) const SizedBox(height: 8),
                Botao('Adicionar receita ou exame',
                    icone: Icons.add, onPressed: () => _abrir(DocumentoFormTela(idosoId: i.id))),
              ],
            ),

            // ---------- Acesso do usuário (RF02) ----------
            Secao(
              titulo: 'Acesso do Usuário',
              subtitulo: 'O usuário entra por um código ou link, sem senha e sem e-mail. '
                  'Reenvie se ${i.pronome.toLowerCase()} trocar de celular.',
              filhos: [
                Center(child: SelectableText(i.codigoAcesso, style: Estilos.codigo)),
                if (!i.codigoValido)
                  Center(
                    child: Text('Código já usado ou vencido: um novo é criado ao enviar.',
                        textAlign: TextAlign.center, style: Estilos.cuidadorLegenda),
                  ),
                const SizedBox(height: 14),
                Botao('Enviar link pelo WhatsApp', icone: Icons.send_outlined, onPressed: () async {
                  await enviarLinkIdoso(context, i);
                  _carregar();
                }),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _avisoOmissao(Idoso i, DoseHoje d, DateTime agora) {
    final atraso = minutosDoDia(TimeOfDay.fromDateTime(agora)) - minutosDoDia(d.hora);
    final h = atraso ~/ 60, m = atraso % 60;
    final tempo = h == 0 ? '${m}min' : (m == 0 ? '${h}h' : '${h}h$m');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(color: Cores.alertaFundo, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.notifications_active, color: Cores.alerta, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${d.nome} (${d.turno.nome.toLowerCase()}) sem confirmação',
                style: Estilos.cuidadorSecao.copyWith(fontSize: 16)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(
            'Ainda não foi marcado como tomado, $tempo depois do horário. Pode ser só '
            'esquecimento de marcar. Que tal ligar para ${i.pronome.toLowerCase()}?',
            style: Estilos.cuidadorCorpo.copyWith(fontSize: 14, color: Cores.alerta.withValues(alpha: 0.95))),
        const SizedBox(height: 12),
        Botao('Ligar pelo WhatsApp',
            tipo: TipoBotao.alerta,
            altura: 46,
            icone: Icons.phone,
            onPressed: () => conversarWhatsApp(context, i.whatsapp)),
      ]),
    );
  }

  Widget _linhaRemedio(Idoso i, Medicamento m) {
    final turnos = m.horarios.map((h) => h.turno).toSet().toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        IconeTurno(turnos.isEmpty ? Turno.manha : turnos.first, tamanho: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${m.nome} • ${m.doseTexto}', style: Estilos.cuidadorCorpo.copyWith(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              [
                m.horarios.map((h) => turnos.length > 1 || m.horarios.length > 1
                    ? '${h.turno.nome} ${horaTexto(h.hora)}'
                    : h.turno.textoPainel).join(', '),
                if (m.finalidade != null) m.finalidade!,
              ].join(' • '),
              style: Estilos.cuidadorLegenda.copyWith(fontSize: 11, color: Cores.texto),
            ),
          ]),
        ),
        IconButton(
          tooltip: 'Editar ${m.nome}',
          icon: const Icon(Icons.edit, size: 20, color: Cores.texto),
          onPressed: () => _abrir(RemedioFormTela(idoso: i, remedio: m)),
        ),
      ]),
    );
  }

  Widget _linhaDocumento(Documento d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(iconeDocumento(d.tipo), size: 22, color: Cores.texto),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.titulo, style: Estilos.cuidadorCorpo.copyWith(fontSize: 14)),
            Text(
              [
                if (d.origem != null) d.origem!,
                if (d.data != null) DateFormat('dd/MM/yyyy').format(d.data!),
              ].join(' • '),
              style: Estilos.cuidadorLegenda.copyWith(fontSize: 11, color: Cores.texto),
            ),
          ]),
        ),
        IconButton(
          tooltip: 'Editar ${d.titulo}',
          icon: const Icon(Icons.edit, size: 20, color: Cores.texto),
          onPressed: () => _abrir(DocumentoFormTela(idosoId: _idosoId, documento: d)),
        ),
      ]),
    );
  }

  /// Chips do Figma: Tomado às 8:05 / Aguardando / Sem confirmação / Às 20:00.
  Widget _chipStatus(DoseHoje d) {
    final (texto, cor) = switch (d.status) {
      'tomado' => ('Tomado às ${horaCurta(d.tomadoEm!)}.', Cores.tomado),
      'atrasado' => ('Sem confirmação', Cores.alertaChip),
      'agora' => ('Aguardando', Cores.faltaTomar),
      _ => ('Às ${horaTexto(d.hora)}', Cores.neutro),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: Estilos.cuidadorLegenda.copyWith(fontSize: 11, color: Cores.texto)),
    );
  }
}
