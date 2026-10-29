import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';

/// Cuidador / 20 Cadastro de remédio (RF03) — também edita, com vários horários.
class RemedioFormTela extends StatefulWidget {
  final Idoso idoso;
  final Medicamento? remedio; // null = novo
  const RemedioFormTela({super.key, required this.idoso, this.remedio});

  @override
  State<RemedioFormTela> createState() => _RemedioFormTelaState();
}

class _RemedioFormTelaState extends State<RemedioFormTela> {
  late final _nome = TextEditingController(text: widget.remedio?.nome);
  late final _dose = TextEditingController(text: widget.remedio?.doseTexto);
  late final _finalidade = TextEditingController(text: widget.remedio?.finalidade);
  late final List<Horario> _horarios = widget.remedio?.horarios
          .map((h) => Horario(id: h.id, hora: h.hora, turno: h.turno))
          .toList() ??
      [Horario(hora: widget.idoso.horaAlmoco, turno: Turno.almoco)];
  late String? _formato = widget.remedio?.formato;
  late String? _cor1 = widget.remedio?.cor;
  late String? _cor2 = widget.remedio?.cor2;
  late String? _fotoPath = widget.remedio?.fotoPath;
  Uint8List? _fotoNova;
  String _fotoExt = 'jpg';
  bool _salvando = false;

  // formatos e as cores de exemplo do Figma (branco, amarelo, vermelho/laranja, azul)
  static const _formatos = <String, (String, String?)>{
    'redondo': ('Branco', null),
    'oval': ('Amarelo', null),
    'capsula': ('Vermelho', 'Laranja'),
    'comprido': ('Azul', null),
  };

  Future<void> _escolherHora(Horario h) async {
    final nova = await showTimePicker(context: context, initialTime: h.hora);
    if (nova == null) return;
    setState(() {
      h.hora = nova;
      h.turno = turnoPelaHora(nova);
    });
  }

  /// Escolher o turno leva o horário para a refeição daquele turno.
  void _escolherTurno(Horario h, Turno t) {
    setState(() {
      if (turnoPelaHora(h.hora) != t) h.hora = widget.idoso.horaDoTurno(t);
      h.turno = t;
    });
  }

  Future<void> _escolherFoto() async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(children: [
          ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(c, ImageSource.camera)),
          ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ]),
      ),
    );
    if (origem == null) return;
    final arq = await ImagePicker().pickImage(source: origem, maxWidth: 1600, imageQuality: 80);
    if (arq == null) return;
    final bytes = await arq.readAsBytes();
    setState(() {
      _fotoNova = bytes;
      _fotoExt = arq.name.contains('.') ? arq.name.split('.').last : 'jpg';
    });
  }

  Future<void> _escolherCor({required bool segunda}) async {
    final escolha = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(segunda ? 'Cor 2' : 'Cor 1', style: Estilos.cuidadorSecao),
            const SizedBox(height: 16),
            Wrap(spacing: 14, runSpacing: 14, children: [
              for (final cor in coresRemedio.entries)
                Semantics(
                  button: true,
                  label: cor.key,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(c, cor.key),
                    child: Column(children: [
                      CircleAvatar(radius: 22, backgroundColor: Cores.borda,
                          child: CircleAvatar(radius: 21, backgroundColor: cor.value)),
                      const SizedBox(height: 4),
                      Text(cor.key, style: Estilos.cuidadorLegenda),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.pop(c, ''), child: const Text('Sem cor')),
          ]),
        ),
      ),
    );
    if (escolha == null) return;
    setState(() {
      final v = escolha.isEmpty ? null : escolha;
      if (segunda) {
        _cor2 = v;
      } else {
        _cor1 = v;
      }
    });
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty || _dose.text.trim().isEmpty) {
      mostrarAviso(context, 'Preencha o nome e quanto tomar.');
      return;
    }
    if (_horarios.isEmpty) {
      mostrarAviso(context, 'Adicione pelo menos um horário.');
      return;
    }
    setState(() => _salvando = true);
    try {
      if (_fotoNova != null) {
        _fotoPath = await Repo.enviarFoto(widget.idoso.id, _fotoNova!, _fotoExt);
      }
      await Repo.salvarMedicamento(Medicamento(
        id: widget.remedio?.id,
        idosoId: widget.idoso.id,
        nome: _nome.text,
        doseTexto: _dose.text,
        finalidade: _finalidade.text,
        fotoPath: _fotoPath,
        formato: _formato,
        cor: _cor1,
        cor2: _cor2,
        horarios: _horarios,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _remover() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Remover ${widget.remedio!.nome}?'),
        content: Text('${widget.idoso.pronome} não verá mais este remédio. O histórico fica guardado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Repo.removerMedicamento(widget.remedio!.id!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 24), children: [
          const BotaoVoltar(),
          const SizedBox(height: 22),
          Text(widget.remedio == null ? 'Cadastro Remédios' : 'Editar Remédio', style: Estilos.cuidadorTitulo),
          const Rotulo('Nome do Remédio'),
          TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              style: Estilos.cuidadorCorpo,
              decoration: const InputDecoration(hintText: 'Ex.: Losartana')),
          const Rotulo('Quanto Tomar'),
          TextField(
              controller: _dose,
              style: Estilos.cuidadorCorpo,
              decoration: const InputDecoration(hintText: 'Ex.: 1 comprimido de 50mg')),
          const Rotulo('Quando tomar'),
          for (final h in _horarios) _editorHorario(h),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() =>
                _horarios.add(Horario(hora: widget.idoso.horaJantar, turno: Turno.noite))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                const Icon(Icons.add_circle_outline, size: 26, color: Cores.texto),
                const SizedBox(width: 10),
                Text('Adicionar mais um horário', style: Estilos.cuidadorRotulo),
              ]),
            ),
          ),
          const Rotulo('Para que serve', extra: '(opcional)'),
          TextField(
              controller: _finalidade,
              style: Estilos.cuidadorCorpo,
              decoration: const InputDecoration(hintText: 'Ex.: Para pressão')),
          const SizedBox(height: 16),
          _botaoFoto(),
          const SizedBox(height: 18),
          Text('Adicione foto da caixa da medicação para melhor atendimento.',
              style: Estilos.cuidadorLegenda.copyWith(fontSize: 10, color: Cores.texto)),
          const Rotulo('Formato do Remédio', extra: '(opcional)'),
          Text('Adicionar tipo e cores do medicamento auxilia a determinar qual medicação tomar.',
              style: Estilos.cuidadorLegenda.copyWith(fontSize: 10, color: Cores.texto)),
          const SizedBox(height: 12),
          _escolhaFormato(),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _botaoCor('Cor 1', _cor1, () => _escolherCor(segunda: false))),
            const SizedBox(width: 12),
            Expanded(child: _botaoCor('Cor 2', _cor2, () => _escolherCor(segunda: true))),
          ]),
          const SizedBox(height: 16),
          Text('A Caixinha só organiza o que o médico receitou. Ela não sugere e nem muda as doses.',
              style: Estilos.cuidadorLegenda.copyWith(fontSize: 10, color: Cores.texto)),
          const SizedBox(height: 22),
          Botao('Salvar', carregando: _salvando, onPressed: _salvar),
          if (widget.remedio != null) ...[
            const SizedBox(height: 14),
            Botao('Remover remédio', tipo: TipoBotao.risco, onPressed: _remover),
          ],
        ]),
      ),
    );
  }

  Widget _editorHorario(Horario h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 40),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _escolherHora(h),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '${h.hora.hour.toString().padLeft(2, '0')} : ${h.hora.minute.toString().padLeft(2, '0')}',
                  textAlign: TextAlign.center,
                  style: Estilos.codigo,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: _horarios.length > 1
                ? IconButton(
                    tooltip: 'Tirar este horário',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _horarios.remove(h)))
                : null,
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (final t in Turno.values) ...[
            if (t != Turno.manha) const SizedBox(width: 12),
            Expanded(
              child: Opcao(
                t.nome,
                selecionado: h.turno == t,
                altura: 56,
                topo: IconeTurno(t,
                    tamanho: 30, cor: h.turno == t ? Cores.textoSobreAcao : Cores.texto, titulo: true),
                onTap: () => _escolherTurno(h, t),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 6),
        Text('${widget.idoso.pronome} vê como “${h.turno.textoTomar}”.',
            style: Estilos.cuidadorLegenda.copyWith(fontSize: 10, color: Cores.texto)),
      ]),
    );
  }

  Widget _botaoFoto() {
    final temFoto = _fotoNova != null || _fotoPath != null;
    return Column(children: [
      if (temFoto)
        Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 10),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: _fotoNova != null
              ? Image.memory(_fotoNova!, fit: BoxFit.cover, width: double.infinity)
              : FotoDoStorage(caminho: _fotoPath!, fit: BoxFit.cover),
        ),
      Material(
        color: Cores.neutro,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _escolherFoto,
          child: SizedBox(
            height: 48,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.photo_camera_outlined, color: Cores.texto),
              const SizedBox(width: 14),
              Text.rich(TextSpan(children: [
                TextSpan(text: temFoto ? 'Trocar foto' : 'Adicionar foto', style: Estilos.cuidadorRotulo),
                if (!temFoto) TextSpan(text: ' (opcional)', style: Estilos.cuidadorCorpo.copyWith(fontSize: 13)),
              ])),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _escolhaFormato() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      for (final f in _formatos.entries)
        Semantics(
          button: true,
          selected: _formato == f.key,
          label: 'Formato ${f.key}',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => setState(() => _formato = _formato == f.key ? null : f.key),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _formato == f.key ? Cores.acao : Colors.transparent, width: 3),
              ),
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size.square(30),
                painter: PinturaComprimido(
                  formato: f.key,
                  // o formato escolhido aparece nas cores escolhidas
                  cor1: corDoRemedio(_formato == f.key && _cor1 != null ? _cor1 : f.value.$1),
                  cor2: _formato == f.key
                      ? (_cor2 == null ? null : corDoRemedio(_cor2))
                      : (f.value.$2 == null ? null : corDoRemedio(f.value.$2)),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _botaoCor(String texto, String? cor, VoidCallback onTap) {
    final fundo = cor == null ? Cores.neutro : corDoRemedio(cor);
    final escuro = fundo.computeLuminance() < 0.6;
    return Material(
      color: fundo,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(cor == null ? texto : '$texto: $cor',
                style: Estilos.cuidadorRotulo.copyWith(color: escuro ? Cores.textoSobreAcao : Cores.texto)),
          ),
        ),
      ),
    );
  }
}
