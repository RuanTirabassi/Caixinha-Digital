import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';

/// Idoso / 03–08 Turno: remédios do turno com "JÁ TOMEI" (RF01 + RF07).
/// Estados do card: pendente, falta tomar (atrasado), ainda não é hora e tomado.
class TomarRemedioTela extends StatefulWidget {
  final Idoso idoso;
  final Turno turno;
  const TomarRemedioTela({super.key, required this.idoso, required this.turno});

  @override
  State<TomarRemedioTela> createState() => _TomarRemedioTelaState();
}

class _TomarRemedioTelaState extends State<TomarRemedioTela> {
  List<DoseHoje>? _doses;
  final Set<String> _salvando = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final todas = await Repo.dosesDeHoje(widget.idoso.id);
      if (mounted) {
        setState(() => _doses = todas.where((d) => d.turno == widget.turno).toList());
      }
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  /// Feedback multissensorial: som + vibração (se ligados pelo cuidador).
  void _feedback() {
    if (widget.idoso.vibracao) HapticFeedback.heavyImpact();
    if (widget.idoso.som) SystemSound.play(SystemSoundType.click);
  }

  Future<void> _jaTomei(DoseHoje d) async {
    setState(() => _salvando.add(d.horarioId));
    try {
      final hora = await Repo.confirmarDose(d.horarioId);
      _feedback();
      if (!mounted) return;
      // Idoso / 06 Turno · Confirmação
      await mostrarDialogoIdoso(
        context,
        icone: 'assets/figma/icone_ok.svg',
        titulo: 'Pronto!\nAnotado: ${d.nome}, às ${horaCurta(hora)}.',
        texto: 'Não precisa guardar de cabeça: ficou anotado!',
        botoes: [
          Builder(
            builder: (c) => Botao('OK',
                tipo: TipoBotao.whatsapp,
                altura: 67,
                estilo: Estilos.idosoBotao,
                onPressed: () => Navigator.pop(c)),
          ),
        ],
      );
      await _carregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando.remove(d.horarioId));
    }
  }

  Future<void> _desfazer(DoseHoje d) async {
    // Idoso / 04 Turno · Desmarcar
    final ok = await mostrarDialogoIdoso<bool>(
      context,
      icone: 'assets/figma/icone_desmarcar.svg',
      titulo: 'Desmarcar este remédio?',
      texto: 'O ${d.nome} vai voltar a aparecer como “Ainda não tomei”.',
      botoes: [
        Builder(
          builder: (c) => Botao('Sim, desmarcar',
              tipo: TipoBotao.alerta,
              altura: 67,
              estilo: Estilos.idosoBotao,
              onPressed: () => Navigator.pop(c, true)),
        ),
        Builder(
          builder: (c) => Botao('Não, deixar como está',
              tipo: TipoBotao.maisTarde,
              altura: 67,
              estilo: Estilos.idosoBotao,
              onPressed: () => Navigator.pop(c, false)),
        ),
      ],
    );
    if (ok != true || !mounted) return;
    setState(() => _salvando.add(d.horarioId));
    try {
      await Repo.desfazerDose(d.doseId!);
      await _carregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando.remove(d.horarioId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(widget.idoso.escalaLetra)),
      child: Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 40, 24, 24), children: [
            const BotaoVoltar(),
            const SizedBox(height: 25),
            Row(children: [
              IconeTurno(widget.turno, tamanho: 34, titulo: true),
              const SizedBox(width: 6),
              Text(widget.turno.nome.toUpperCase(), style: Estilos.idosoTitulo),
            ]),
            const SizedBox(height: 16),
            if (_doses == null)
              const Center(child: CircularProgressIndicator())
            else if (_doses!.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text('Nenhum remédio neste horário.', style: Estilos.idosoCorpo),
              )
            else
              for (final d in _doses!) _cardRemedio(d),
          ]),
        ),
      ),
    );
  }

  Widget _cardRemedio(DoseHoje d) {
    final ocupado = _salvando.contains(d.horarioId);
    final atrasado = d.status == 'atrasado' && !d.tomado;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: atrasado ? Cores.faltaTomar : Cores.cartao,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              d.fotoPath == null
                  ? Comprimido(formato: d.formato, cor1: d.cor, cor2: d.cor2, nome: d.nome)
                  : ClipOval(
                      child: SizedBox(
                          width: 76, height: 76, child: FotoDoStorage(caminho: d.fotoPath!, fit: BoxFit.cover)),
                    ),
              if (d.fotoPath != null)
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FotoTelaCheia(titulo: d.nome, caminho: d.fotoPath!))),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Ver foto', style: Estilos.idosoCorpo.copyWith(color: Cores.textoSuave)),
                  ),
                ),
            ]),
            const SizedBox(width: 20),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.nome, style: Estilos.idosoTitulo),
                const SizedBox(height: 4),
                Text(d.doseTexto, style: Estilos.idosoCorpo),
                Text(d.turno.textoTomar, style: Estilos.idosoCorpo),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        if (d.tomado) ...[
          // Idoso / 03 Turno · Manhã tomado
          Container(
            constraints: const BoxConstraints(minHeight: 62),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Cores.tomado, borderRadius: BorderRadius.circular(16)),
            child: Text('Tomado às ${horaCurta(d.tomadoEm!)}.', style: Estilos.idosoCorpo),
          ),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: ocupado ? null : () => _desfazer(d),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SvgPicture.asset('assets/figma/fechar.svg', width: 24, height: 24),
                const SizedBox(width: 14),
                Text('Marquei por engano.', style: Estilos.idosoCorpo),
              ]),
            ),
          ),
        ] else if (d.status == 'futuro')
          // Idoso / 07 Turno · Noite mais tarde
          Container(
            constraints: const BoxConstraints(minHeight: 72),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Cores.maisTarde, borderRadius: BorderRadius.circular(16)),
            child: Text('Ainda não é hora.\nVou te lembrar às ${horaTexto(d.hora)}.',
                textAlign: TextAlign.center, style: Estilos.idosoCorpo),
          )
        else ...[
          // Idoso / 05 Almoço pendente e 08 Falta tomar
          Botao('JÁ TOMEI ESTE REMÉDIO',
              altura: 94,
              estilo: Estilos.idosoBotao,
              carregando: ocupado,
              iconeWidget: SvgPicture.asset('assets/figma/check_botao.svg', width: 40, height: 29),
              onPressed: () => _jaTomei(d)),
          if (atrasado)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text('FALTA TOMAR!', textAlign: TextAlign.center, style: Estilos.idosoDestaque),
            ),
        ],
      ]),
    );
  }
}
