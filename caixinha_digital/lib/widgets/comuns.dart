import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../tema.dart';

// Componentes da página "Recursos" do Figma (Comp / …).

/// Comp / Voltar — botão cinza "← VOLTAR" das telas internas.
class BotaoVoltar extends StatelessWidget {
  final Color? corTexto;
  final Color? corFundo;
  const BotaoVoltar({super.key, this.corTexto, this.corFundo});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: corFundo ?? Cores.neutro,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(),
          child: SizedBox(
            width: 127,
            height: 36,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SvgPicture.asset('assets/figma/voltar_seta.svg',
                  width: 24,
                  height: 24,
                  colorFilter: corTexto == null ? null : ColorFilter.mode(corTexto!, BlendMode.srcIn)),
              const SizedBox(width: 6),
              Text('VOLTAR', style: Estilos.voltar.copyWith(color: corTexto)),
            ]),
          ),
        ),
      ),
    );
  }
}

enum TipoBotao { principal, secundario, risco, whatsapp, alerta, maisTarde }

/// Comp / Botão principal, secundário e de risco (62 de altura, cantos 16).
class Botao extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final TipoBotao tipo;
  final IconData? icone;
  final Widget? iconeWidget;
  final bool carregando;
  final double altura;
  final TextStyle? estilo;

  const Botao(
    this.texto, {
    super.key,
    required this.onPressed,
    this.tipo = TipoBotao.principal,
    this.icone,
    this.iconeWidget,
    this.carregando = false,
    this.altura = 62,
    this.estilo,
  });

  @override
  Widget build(BuildContext context) {
    final (fundo, frente, borda) = switch (tipo) {
      TipoBotao.principal => (Cores.acao, Cores.textoSobreAcao, null),
      TipoBotao.secundario => (Cores.neutro, Cores.texto, null),
      TipoBotao.risco => (Cores.cartao, Cores.alerta, Cores.alerta),
      TipoBotao.whatsapp => (Cores.okVerde, Cores.textoSobreAcao, null),
      TipoBotao.alerta => (Cores.alerta, Cores.textoSobreAcao, null),
      TipoBotao.maisTarde => (Cores.maisTarde, Cores.texto, null),
    };
    final style = (estilo ?? Estilos.cuidadorSecao).copyWith(color: frente);
    return Material(
      color: onPressed == null && !carregando ? fundo.withValues(alpha: 0.5) : fundo,
      borderRadius: BorderRadius.circular(16),
      shape: borda == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), side: BorderSide(color: borda, width: 2)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: carregando ? null : onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: altura),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Center(
              child: carregando
                  ? SizedBox(
                      width: 26, height: 26, child: CircularProgressIndicator(color: frente, strokeWidth: 3))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (iconeWidget != null) ...[iconeWidget!, const SizedBox(width: 12)],
                      if (icone != null) ...[Icon(icone, color: frente, size: 24), const SizedBox(width: 12)],
                      Flexible(child: Text(texto, textAlign: TextAlign.center, style: style)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Comp / Interruptor — azul com bolinha à direita (ligado) ou cinza (desligado).
class Interruptor extends StatelessWidget {
  final bool ligado;
  final ValueChanged<bool>? onChanged;
  const Interruptor({super.key, required this.ligado, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: ligado,
      button: true,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!ligado),
        child: Opacity(
          opacity: onChanged == null ? 0.6 : 1,
          child: SvgPicture.asset(
            ligado ? 'assets/figma/interruptor_ligado.svg' : 'assets/figma/interruptor_desligado.svg',
            width: 56,
            height: 32,
          ),
        ),
      ),
    );
  }
}

/// Comp / Opção — azul quando selecionado, cinza quando não.
class Opcao extends StatelessWidget {
  final String texto;
  final bool selecionado;
  final VoidCallback onTap;
  final double altura;
  final Widget? topo;
  const Opcao(this.texto,
      {super.key, required this.selecionado, required this.onTap, this.altura = 48, this.topo});

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? Cores.textoSobreAcao : Cores.texto;
    return Material(
      color: selecionado ? Cores.acao : Cores.neutro,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: altura),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              if (topo != null) topo!,
              Text(texto, textAlign: TextAlign.center, style: Estilos.cuidadorCorpo.copyWith(color: cor)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Linha de opções que dividem a largura (ex.: Nenhum / Senhor / Senhora).
class GrupoOpcoes<T> extends StatelessWidget {
  final Map<T, String> opcoes;
  final T valor;
  final ValueChanged<T> onChanged;
  final double altura;
  const GrupoOpcoes(
      {super.key, required this.opcoes, required this.valor, required this.onChanged, this.altura = 36});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (final o in opcoes.entries) ...[
        if (o.key != opcoes.keys.first) const SizedBox(width: 8),
        Expanded(
          child: Opcao(o.value, selecionado: o.key == valor, altura: altura, onTap: () => onChanged(o.key)),
        ),
      ],
    ]);
  }
}

/// Comp / Linha de navegação — título, detalhe e seta ›.
class LinhaNavegacao extends StatelessWidget {
  final String titulo;
  final String? detalhe;
  final VoidCallback onTap;
  const LinhaNavegacao({super.key, required this.titulo, this.detalhe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Expanded(child: _Textos(titulo: titulo, detalhe: detalhe)),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, size: 28, color: Cores.texto),
          ]),
        ),
      ),
    );
  }
}

/// Comp / Linha com interruptor.
class LinhaComInterruptor extends StatelessWidget {
  final String titulo;
  final String? detalhe;
  final bool valor;
  final ValueChanged<bool>? onChanged;
  const LinhaComInterruptor(
      {super.key, required this.titulo, this.detalhe, required this.valor, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!valor),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Expanded(child: _Textos(titulo: titulo, detalhe: detalhe)),
            const SizedBox(width: 12),
            Interruptor(ligado: valor, onChanged: onChanged),
          ]),
        ),
      ),
    );
  }
}

class _Textos extends StatelessWidget {
  final String titulo;
  final String? detalhe;
  const _Textos({required this.titulo, this.detalhe});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: Estilos.cuidadorCorpo),
      if (detalhe != null) ...[
        const SizedBox(height: 2),
        Text(detalhe!, style: Estilos.cuidadorLegenda),
      ],
    ]);
  }
}

/// Linhas separadas por um traço fino (como nas Configurações).
class Linhas extends StatelessWidget {
  final List<Widget> filhos;
  const Linhas(this.filhos, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var i = 0; i < filhos.length; i++) ...[
        if (i > 0) const Divider(),
        filhos[i],
      ],
    ]);
  }
}

/// Card cinza claro com título (painel e configurações).
class Secao extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> filhos;
  final Color? cor;
  const Secao({super.key, required this.titulo, this.subtitulo, required this.filhos, this.cor});

  @override
  Widget build(BuildContext context) {
    // Material (e não Container com cor): os ListTile/InkWell de dentro
    // precisam dele para pintar o toque; senão o Flutter acusa erro em debug.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: cor ?? Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: _conteudo(),
        ),
      ),
    );
  }

  Widget _conteudo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: Estilos.cuidadorSecao),
      if (subtitulo != null) ...[
        const SizedBox(height: 4),
        Text(subtitulo!, style: Estilos.cuidadorLegenda.copyWith(color: Cores.texto)),
      ],
      const SizedBox(height: 12),
      ...filhos,
    ]);
  }
}

/// Rótulo de campo em negrito, com complemento opcional: "Para que serve (opcional)".
class Rotulo extends StatelessWidget {
  final String texto;
  final String? extra;
  const Rotulo(this.texto, {super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: texto, style: Estilos.cuidadorRotulo),
        if (extra != null) TextSpan(text: ' $extra', style: Estilos.cuidadorCorpo.copyWith(fontSize: 14)),
      ])),
    );
  }
}

/// Campo de WhatsApp do Figma: "+55" e uma linha embaixo do número.
class CampoWhatsApp extends StatelessWidget {
  final TextEditingController controller;
  const CampoWhatsApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('+55', style: Estilos.cuidadorCorpo),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          style: Estilos.cuidadorCorpo,
          decoration: InputDecoration(
            hintText: 'Ex.: 43 99999-9999',
            counterText: '',
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 4),
            border: const UnderlineInputBorder(borderSide: BorderSide(color: Cores.borda)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Cores.borda)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Cores.acao, width: 2)),
          ),
        ),
      ),
    ]);
  }
}

/// Ícones de turno do Figma (sol, prato e lua).
class IconeTurno extends StatelessWidget {
  final Turno turno;
  final double tamanho;
  final Color? cor;
  /// Nos títulos ("ALMOÇO", "• Almoço • 12:22") o Figma usa outro talher.
  final bool titulo;
  const IconeTurno(this.turno, {super.key, this.tamanho = 28, this.cor, this.titulo = false});

  @override
  Widget build(BuildContext context) {
    final filtro = cor == null ? null : ColorFilter.mode(cor!, BlendMode.srcIn);
    if (titulo && turno == Turno.almoco) {
      return SizedBox(
        width: tamanho,
        height: tamanho,
        child: Center(
          child: SvgPicture.asset('assets/figma/prato_titulo.svg',
              height: tamanho * 0.9, width: tamanho * 0.9 * 18.2 / 22.4, colorFilter: filtro),
        ),
      );
    }
    final arquivo = switch (turno) {
      Turno.manha => 'sol',
      Turno.almoco => 'prato',
      Turno.noite => 'lua',
    };
    // a lua do Figma é um pouco menor (24 em vez de 28)
    final t = turno == Turno.noite ? tamanho * 24 / 28 : tamanho;
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: Center(
        child: SvgPicture.asset('assets/figma/$arquivo.svg',
            width: t, height: t, colorFilter: filtro),
      ),
    );
  }
}

/// Botão redondo da engrenagem (canto da tela).
class BotaoEngrenagem extends StatelessWidget {
  final VoidCallback onTap;
  final String dica;
  const BotaoEngrenagem({super.key, required this.onTap, required this.dica});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: dica,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: SvgPicture.asset('assets/figma/botao_config.svg', width: 64, height: 64),
      ),
    );
  }
}

// ---------------- Cores dos remédios (Cor 1 / Cor 2) ----------------
const coresRemedio = <String, Color>{
  'Branco': Color(0xFFF2F2F2),
  'Amarelo': Color(0xFFFFC928),
  'Laranja': Color(0xFFF9A63A),
  'Vermelho': Color(0xFFE5392C),
  'Rosa': Color(0xFFF7B2C4),
  'Azul': Color(0xFF9FC3E7),
  'Verde': Color(0xFFA5D6A7),
  'Marrom': Color(0xFFA1887F),
  'Preto': Color(0xFF333333),
};

Color corDoRemedio(String? nome, [Color padrao = const Color(0xFFF2F2F2)]) =>
    coresRemedio[nome] ?? padrao;

/// Desenho do comprimido no formato e nas cores escolhidos pelo cuidador.
/// Sem formato: mostra a inicial do remédio (como o "S" da Sinvastatina no Figma).
class Comprimido extends StatelessWidget {
  final String? formato;
  final String? cor1;
  final String? cor2;
  final String nome;
  final double tamanho;
  const Comprimido(
      {super.key, this.formato, this.cor1, this.cor2, required this.nome, this.tamanho = 76});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: formato == null
          ? Text(nome.isEmpty ? '?' : nome.characters.first.toUpperCase(),
              style: Estilos.idosoTitulo.copyWith(color: Colors.white, fontSize: tamanho * 0.5))
          : CustomPaint(
              size: Size.square(tamanho * 0.62),
              painter: PinturaComprimido(
                formato: formato!,
                cor1: corDoRemedio(cor1),
                cor2: cor2 == null ? null : corDoRemedio(cor2),
              ),
            ),
    );
  }
}

class PinturaComprimido extends CustomPainter {
  final String formato;
  final Color cor1;
  final Color? cor2;
  PinturaComprimido({required this.formato, required this.cor1, this.cor2});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final w = size.width;
    final contorno = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;
    final brilho = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.05;

    switch (formato) {
      case 'redondo':
      case 'oval':
        final r = formato == 'redondo' ? w * 0.5 : w * 0.38;
        canvas.drawCircle(c, r, Paint()..color = cor1);
        canvas.drawCircle(c, r, contorno);
        // risco do meio (comprimido sulcado)
        canvas.drawLine(c + Offset(-r * 0.6, r * 0.6), c + Offset(r * 0.6, -r * 0.6),
            Paint()
              ..color = Colors.black.withValues(alpha: 0.15)
              ..strokeWidth = w * 0.04);
      default: // capsula | comprido
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(-49 * math.pi / 180);
        final comp = w * (formato == 'comprido' ? 1.15 : 1.05);
        final alt = w * (formato == 'comprido' ? 0.40 : 0.46);
        final rr = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: comp, height: alt), Radius.circular(alt / 2));
        canvas.drawRRect(rr, Paint()..color = cor1);
        if (cor2 != null) {
          canvas.save();
          canvas.clipRect(Rect.fromLTRB(0, -alt, comp, alt));
          canvas.drawRRect(rr, Paint()..color = cor2!);
          canvas.restore();
        } else if (formato == 'comprido') {
          canvas.drawLine(Offset(0, -alt * 0.35), Offset(0, alt * 0.35),
              Paint()
                ..color = Colors.black.withValues(alpha: 0.15)
                ..strokeWidth = w * 0.04);
        }
        canvas.drawRRect(rr, contorno);
        canvas.drawLine(Offset(-comp * 0.3, -alt * 0.2), Offset(-comp * 0.1, -alt * 0.2), brilho);
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(PinturaComprimido old) =>
      old.formato != formato || old.cor1 != cor1 || old.cor2 != cor2;
}

/// Caixa de diálogo grande do idoso (fundo escurecido, card cinza).
Future<T?> mostrarDialogoIdoso<T>(BuildContext context,
    {required String icone, required String titulo, String? texto, required List<Widget> botoes}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x85000000),
    builder: (c) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Cores.cartao,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.asset(icone, width: 76, height: 76),
          const SizedBox(height: 16),
          Text(titulo, textAlign: TextAlign.center, style: Estilos.idosoTitulo),
          if (texto != null) ...[
            const SizedBox(height: 14),
            Text(texto, textAlign: TextAlign.center, style: Estilos.idosoCorpo),
          ],
          const SizedBox(height: 18),
          for (var i = 0; i < botoes.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: botoes[i]),
          ],
        ]),
      ),
    ),
  );
}

/// Mostra uma foto do storage (com link temporário).
class FotoDoStorage extends StatelessWidget {
  final String caminho;
  final BoxFit fit;
  const FotoDoStorage({super.key, required this.caminho, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: Repo.linkDaFoto(caminho),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return Image.network(snap.data!, fit: fit);
      },
    );
  }
}

/// Foto em tela cheia com zoom de dois dedos.
class FotoTelaCheia extends StatelessWidget {
  final String titulo;
  final String caminho;
  const FotoTelaCheia({super.key, required this.titulo, required this.caminho});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              const BotaoVoltar(),
              const SizedBox(width: 14),
              Expanded(child: Text(titulo, style: Estilos.idosoDestaque.copyWith(color: Colors.white))),
            ]),
          ),
          Expanded(child: InteractiveViewer(maxScale: 6, child: FotoDoStorage(caminho: caminho))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Use dois dedos para aumentar',
                style: Estilos.idosoCorpo.copyWith(color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

void mostrarErro(BuildContext context, Object erro) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(mensagemDeErro(erro)),
    backgroundColor: Cores.alerta,
  ));
}

void mostrarAviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

/// "Terça-feira, 20 de Outubro" (o Figma usa o mês com maiúscula).
String capitalizarPalavras(String s) => s
    .split(' ')
    .map((p) => p.length > 2 ? p[0].toUpperCase() + p.substring(1) : p)
    .join(' ');
