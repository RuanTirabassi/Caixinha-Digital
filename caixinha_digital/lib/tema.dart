import 'package:flutter/material.dart';

/// Cores e tipografia do protótipo no Figma (variáveis "cor/…" e "estado/…").
/// Diretrizes de IHC: fonte mínima 18 para o idoso, botões >= 56dp, alto contraste.
class Cores {
  // cor/…
  static const texto = Color(0xFF000000);
  static const textoSuave = Color(0xFF363636);
  static const cartao = Color(0xFFF0F0F0);
  static const neutro = Color(0xFFD9D9D9);
  static const borda = Color(0xFFB6B6B6);
  static const acao = Color(0xFF0062B8);
  static const acaoEscura = Color(0xFF00215F);
  static const textoSobreAcao = Color(0xFFFFFFFF);
  // estado/…
  static const pendente = Color(0xFFFFCC00);
  static const tomado = Color(0xFF37DB00);
  static const tomadoTexto = Color(0xFF124600);
  static const alerta = Color(0xFFD43328);
  static const maisTarde = Color(0xFFC8C8C8);
  // usadas direto nas telas do Figma
  static const okVerde = Color(0xFF00822C); // botão OK / WhatsApp
  static const faltaTomar = Color(0xFFE6DCB4); // card "FALTA TOMAR!" e chip "Aguardando"
  static const emDia = Color(0x4A34D000); // faixa "Seus remédios estão em dia"
  static const alertaFundo = Color(0xFFF8B7B2); // card "sem confirmação" do painel
  static const alertaChip = Color(0xFFFAC5C1); // chip "Sem confirmação"
  static const receita = Color(0xFFBBD3EE);
  static const exame = Color(0xFFFFE08A);
}

/// Estilos de texto do Figma (Idoso/…, Cuidador/…, Comum/…). Fonte Inter.
class Estilos {
  static const _base = TextStyle(fontFamily: 'Inter', height: 1.25, color: Cores.texto);

  // Idoso
  static final idosoTitulo = _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700);
  static final idosoCorpo = _base.copyWith(fontSize: 18);
  static final idosoDestaque = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w700);
  static final idosoBotao = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w700);

  // Cuidador
  static final cuidadorTitulo = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w700);
  static final cuidadorSecao = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w700);
  static final cuidadorCorpo = _base.copyWith(fontSize: 16);
  static final cuidadorRotulo = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w700);
  static final cuidadorLegenda = _base.copyWith(fontSize: 12, color: Cores.textoSuave);
  static final codigo = _base.copyWith(fontSize: 28, fontWeight: FontWeight.w700);

  // Comum
  static final voltar = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w700);
}

ThemeData criarTema() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: Cores.acao,
      primary: Cores.acao,
      surface: Colors.white,
      error: Cores.alerta,
    ),
    scaffoldBackgroundColor: Colors.white,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Inter', bodyColor: Cores.texto, displayColor: Cores.texto),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(62),
        backgroundColor: Cores.acao,
        foregroundColor: Cores.textoSobreAcao,
        textStyle: Estilos.cuidadorSecao,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      hintStyle: Estilos.cuidadorCorpo.copyWith(color: Cores.textoSuave.withValues(alpha: 0.7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Cores.borda)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Cores.borda)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Cores.acao, width: 2)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Cores.cartao,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: Estilos.cuidadorTitulo,
      contentTextStyle: Estilos.cuidadorCorpo,
    ),
    snackBarTheme: SnackBarThemeData(contentTextStyle: Estilos.idosoCorpo.copyWith(color: Colors.white)),
    dividerTheme: const DividerThemeData(color: Cores.borda, thickness: 1, space: 1),
  );
}
