import 'package:flutter/material.dart';

/// Paleta de cores oficial do NOVAML.
/// Inspirada em interfaces científicas espaciais — dark, profunda, com accent
/// cósmico para destacar ações e classificações astronômicas.
abstract final class AppColors {
  // ── Background layers ──────────────────────────────────────────────────────
  /// Fundo mais profundo — janela principal.
  static const Color surface0 = Color(0xFF0A0D14);

  /// Fundo de cards e painéis.
  static const Color surface1 = Color(0xFF111620);

  /// Fundo de elementos elevados (dialogs, dropdowns).
  static const Color surface2 = Color(0xFF181E2C);

  /// Borda sutil entre elementos.
  static const Color border = Color(0xFF1F2738);

  /// Borda hover / active.
  static const Color borderActive = Color(0xFF2E3D5C);

  // ── Brand / Accent ─────────────────────────────────────────────────────────
  /// Accent primário — cyan cósmico (identidade NOVAML).
  static const Color accent = Color(0xFF00CFDE);

  /// Accent hover.
  static const Color accentHover = Color(0xFF33DAEA);

  /// Accent pressionado.
  static const Color accentPressed = Color(0xFF00A8B5);

  /// Accent com opacidade baixa — fundos de seleção.
  static const Color accentSubtle = Color(0x1A00CFDE);

  /// Accent para texto e ícones sobre fundo escuro.
  static const Color accentText = Color(0xFF4FD6E4);

  // ── Texto ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE8EDF5);
  static const Color textSecondary = Color(0xFF8A95A8);
  static const Color textDisabled = Color(0xFF3E4A5C);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Semânticas ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34C46A);
  static const Color successSubtle = Color(0x1A34C46A);
  static const Color warning = Color(0xFFF5A623);
  static const Color warningSubtle = Color(0x1AF5A623);
  static const Color error = Color(0xFFE8485A);
  static const Color errorSubtle = Color(0x1AE8485A);
  static const Color info = Color(0xFF4F8EF7);
  static const Color infoSubtle = Color(0x1A4F8EF7);

  // ── Classificações astronômicas ────────────────────────────────────────────
  /// Estrelas — amarelo-dourado solar.
  static const Color star = Color(0xFFFFD166);
  static const Color starSubtle = Color(0x1AFFD166);

  /// Galáxias — violeta nebulosa.
  static const Color galaxy = Color(0xFFB57BFF);
  static const Color galaxySubtle = Color(0x1AB57BFF);

  /// Quasares — ciano energético.
  static const Color quasar = Color(0xFF3DD8D8);
  static const Color quasarSubtle = Color(0x1A3DD8D8);

  // ── Sidebar ────────────────────────────────────────────────────────────────
  static const Color sidebarBackground = Color(0xFF0D1119);
  static const Color sidebarItemHover = Color(0xFF161C2A);
  static const Color sidebarItemActive = Color(0xFF1A2540);
}
