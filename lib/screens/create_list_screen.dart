import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/shopping_list_repository.dart';
import '../theme/fresh_sprout_tokens.dart';
import '../utils/currency_input_formatter.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({
    super.key,
    this.isDarkMode,
    this.onToggleTheme,
  });

  final bool? isDarkMode;
  final VoidCallback? onToggleTheme;

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

abstract final class _CreateListSpec {
  static const headerBtnSize = 42.0;
  static const cardRadius = 16.0;
  static const chipRadius = 12.0;
  static const emojiBtnSize = 32.0;
  static const micBtnSize = 34.0;
  static const micBtnSizeActive = 80.0;
}

abstract final class _CreateListColors {
  static const brandEmerald = Color(0xFF0D8259);
  static const brandAmber = Color(0xFFF1A410);

  static const lightBg = Color(0xFFF4FBF4);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFEEF8EF);
  static const lightBorder = Color(0xFFD9E8DA);
  static const lightMuted = Color(0xFF617467);

  static const darkBg = Color(0xFF191D2D);
  static const darkCard = Color(0xFF222738);
  static const darkSurface = Color(0xFF2C3246);
  static const darkBorder = Color(0xFF34394B);
  static const darkMuted = Color(0xFF8E96AA);

  static List<BoxShadow> glowEmerald(bool enabled) => enabled
      ? [
          BoxShadow(
            color: brandEmerald.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ]
      : const [];

  static List<BoxShadow> glowAmber(bool enabled) => enabled
      ? [
          BoxShadow(
            color: brandAmber.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ]
      : const [];
}

class _Suggestion {
  const _Suggestion(this.emoji, this.label);

  final String emoji;
  final String label;
}

class _CreateListScreenState extends State<CreateListScreen>
    with TickerProviderStateMixin {
  final _repository = ShoppingListRepository.instance;
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _speech = SpeechToText();
  bool _isSaving = false;
  bool _speechReady = false;
  bool _isListening = false;
  bool _micHeld = false;
  bool _speechStopping = false;
  bool _speechInitStarted = false;
  DateTime? _micPressStartedAt;
  String _dictationPrefix = '';
  static const _minMicHoldDuration = Duration(milliseconds: 400);
  String _selectedEmoji = '🛒';
  final _soundLevelNotifier = ValueNotifier(0.0);
  late final AnimationController _pulseController;

  static const _suggestions = [
    _Suggestion('🥬', 'Compras Semanal'),
    _Suggestion('🛒', 'Compras do Mês'),
    _Suggestion('🥩', 'Churrasco & Amigos'),
    _Suggestion('📦', 'Abastecer Despensa'),
    _Suggestion('🍎', 'Hortifruti Fresco'),
    _Suggestion('💊', 'Farmácia & Saúde'),
  ];

  static const _emojiOptions = [
    '🛒',
    '🍎',
    '🎉',
    '🧴',
    '🥬',
    '🥩',
  ];

  bool _isDark(BuildContext context) =>
      widget.isDarkMode ?? Theme.of(context).brightness == Brightness.dark;

  Color _accent(bool isDark) =>
      isDark ? _CreateListColors.brandAmber : _CreateListColors.brandEmerald;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  Future<void> _initSpeech() async {
    if (_speechInitStarted) return;
    _speechInitStarted = true;

    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (!mounted || _micHeld || _speechStopping) return;
        if (status == 'done' || status == 'notListening') {
          if (_isListening) setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (!mounted || _micHeld || _speechStopping) return;
        if (_isListening) setState(() => _isListening = false);
      },
    );
  }

  double _normalizeSoundLevel(double level) {
    if (level <= 0) {
      return ((level + 45) / 45).clamp(0.0, 1.0);
    }
    return (level / 12).clamp(0.0, 1.0);
  }

  Future<String?> _speechLocale() async {
    final locales = await _speech.locales();
    if (locales.isEmpty) return null;

    for (final locale in locales) {
      if (locale.localeId.startsWith('pt')) return locale.localeId;
    }
    return locales.first.localeId;
  }

  @override
  void dispose() {
    _speech.stop();
    _soundLevelNotifier.dispose();
    _nameController.dispose();
    _budgetController.dispose();
    _nameFocusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _selectSuggestion(_Suggestion suggestion) {
    _nameController.text = suggestion.label;
    _nameController.selection =
        TextSelection.collapsed(offset: suggestion.label.length);
    setState(() => _selectedEmoji = suggestion.emoji);
    _nameFocusNode.requestFocus();
  }

  void _clearName() {
    _nameController.clear();
    _nameFocusNode.requestFocus();
  }

  void _applySpeechResult(String words) {
    if (!mounted) return;

    final trimmed = words.trim();
    if (trimmed.isEmpty) return;

    final text = _dictationPrefix.isEmpty
        ? trimmed
        : '$_dictationPrefix $trimmed';

    if (_nameController.text == text) return;

    _nameController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _beginListening() async {
    if (!_micHeld || !_speechReady || !mounted) return;

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }
    if (!_micHeld || !mounted) return;

    final localeId = await _speechLocale();
    if (!_micHeld || !mounted) return;

    try {
      await _speech.listen(
        onResult: (result) => _applySpeechResult(result.recognizedWords),
        onSoundLevelChange: (level) {
          if (!_micHeld) return;
          _soundLevelNotifier.value = _normalizeSoundLevel(level);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5),
        ),
      );
    } catch (_) {
      if (!mounted || !_micHeld) return;
      _micHeld = false;
      setState(() => _isListening = false);
    }
  }

  Future<void> _onMicPressStart() async {
    if (_micHeld) return;

    _dictationPrefix = _nameController.text.trim();
    _micPressStartedAt = DateTime.now();
    _micHeld = true;
    HapticFeedback.mediumImpact();
    setState(() {});

    if (!_speechReady) {
      await _initSpeech();
    }

    if (!_speechReady) {
      _micHeld = false;
      _micPressStartedAt = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Use o microfone do teclado para ditar o nome da lista',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() => _isListening = true);
    _soundLevelNotifier.value = 0;
    unawaited(_beginListening());
  }

  Future<void> _onMicPressEnd() async {
    if (!_micHeld) return;

    final pressStartedAt = _micPressStartedAt;
    _micPressStartedAt = null;
    final quickTap = pressStartedAt != null &&
        DateTime.now().difference(pressStartedAt) < _minMicHoldDuration;

    _micHeld = false;
    _speechStopping = true;
    HapticFeedback.lightImpact();

    if (mounted) {
      setState(() => _isListening = false);
    }

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {
      // Ignora falhas ao encerrar a sessão de ditado.
    } finally {
      _speechStopping = false;
      _soundLevelNotifier.value = 0;
    }

    if (quickTap && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pressione e segure para falar'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    final budget = CurrencyInputFormatter.parseFormattedPrice(
      _budgetController.text.trim(),
    );

    final list = await _repository.createList(
      _nameController.text.trim(),
      emoji: _selectedEmoji,
      budgetCeiling: budget != null && budget > 0 ? budget : null,
    );

    if (!mounted) return;

    Navigator.of(context).pop(list.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final accent = _accent(isDark);
    final bg = isDark ? _CreateListColors.darkBg : _CreateListColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CreateListHeader(
              isDarkMode: isDark,
              accent: accent,
              onBack: () => Navigator.of(context).pop(),
              onToggleTheme: widget.onToggleTheme,
              pulseAnimation: _pulseController,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroSection(isDarkMode: isDark, accent: accent),
                    const SizedBox(height: 24),
                    _NameInputCard(
                      isDarkMode: isDark,
                      accent: accent,
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      isMicHeld: _micHeld,
                      isListening: _isListening,
                      soundLevelListenable: _soundLevelNotifier,
                      onClear: _clearName,
                      onMicPressStart: _onMicPressStart,
                      onMicPressEnd: _onMicPressEnd,
                      onSubmitted: _submit,
                    ),
                    const SizedBox(height: 24),
                    _SuggestionsSection(
                      isDarkMode: isDark,
                      accent: accent,
                      suggestions: _suggestions,
                      onSelect: _selectSuggestion,
                    ),
                    const SizedBox(height: 12),
                    _EmojiCategoryCard(
                      isDarkMode: isDark,
                      accent: accent,
                      options: _emojiOptions,
                      selected: _selectedEmoji,
                      onSelected: (emoji) =>
                          setState(() => _selectedEmoji = emoji),
                    ),
                    const SizedBox(height: 12),
                    _BudgetCard(
                      isDarkMode: isDark,
                      accent: accent,
                      controller: _budgetController,
                    ),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameController,
              builder: (context, value, _) {
                return _SubmitFooter(
                  isDarkMode: isDark,
                  enabled: value.text.trim().isNotEmpty && !_isSaving,
                  isSaving: _isSaving,
                  onPressed: _submit,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateListHeader extends StatelessWidget {
  const _CreateListHeader({
    required this.isDarkMode,
    required this.accent,
    required this.onBack,
    required this.onToggleTheme,
    required this.pulseAnimation,
  });

  final bool isDarkMode;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback? onToggleTheme;
  final AnimationController pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final bg = isDarkMode ? _CreateListColors.darkBg : _CreateListColors.lightBg;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: (isDarkMode
                        ? _CreateListColors.darkBorder
                        : _CreateListColors.lightBorder)
                    .withValues(alpha: isDarkMode ? 0.6 : 0.5),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                _HeaderIconButton(
                  isDarkMode: isDarkMode,
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: onBack,
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? _CreateListColors.darkCard
                            : _CreateListColors.lightSurface,
                        borderRadius: FreshSproutRadius.fullBorder,
                        border: Border.all(
                          color: isDarkMode
                              ? _CreateListColors.darkBorder
                                  .withValues(alpha: 0.8)
                              : _CreateListColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: pulseAnimation,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _CreateListColors.brandEmerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Etapa 1 de 2',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  color: accent,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _HeaderIconButton(
                  isDarkMode: isDarkMode,
                  icon: isDarkMode
                      ? Icons.wb_sunny_outlined
                      : Icons.dark_mode_outlined,
                  iconColor: isDarkMode ? accent : _CreateListColors.lightMuted,
                  onPressed: onToggleTheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.isDarkMode,
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  final bool isDarkMode;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDarkMode
          ? _CreateListColors.darkCard
          : _CreateListColors.lightCard,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _CreateListSpec.headerBtnSize,
          height: _CreateListSpec.headerBtnSize,
          child: Icon(
            icon,
            size: 20,
            color: iconColor ??
                (isDarkMode
                    ? FreshSproutColors.darkTextSecondary
                    : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.isDarkMode,
    required this.accent,
  });

  final bool isDarkMode;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final badgeBg = isDarkMode
        ? accent.withValues(alpha: 0.1)
        : const Color(0xFFD1FAE5);
    final badgeFg = isDarkMode ? accent : _CreateListColors.brandEmerald;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '✨ Nova experiência de compras',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: badgeFg,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Vamos começar!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDarkMode
                    ? Colors.white
                    : const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Dê um nome para a sua nova lista de compras ou escolha '
          'uma das opções sugeridas.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? _CreateListColors.darkMuted
                    : _CreateListColors.lightMuted,
              ),
        ),
      ],
    );
  }
}

class _NameInputCard extends StatelessWidget {
  const _NameInputCard({
    required this.isDarkMode,
    required this.accent,
    required this.controller,
    required this.focusNode,
    required this.isMicHeld,
    required this.isListening,
    required this.soundLevelListenable,
    required this.onClear,
    required this.onMicPressStart,
    required this.onMicPressEnd,
    required this.onSubmitted,
  });

  final bool isDarkMode;
  final Color accent;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isMicHeld;
  final bool isListening;
  final ValueListenable<double> soundLevelListenable;
  final VoidCallback onClear;
  final VoidCallback onMicPressStart;
  final VoidCallback onMicPressEnd;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final cardBg =
        isDarkMode ? _CreateListColors.darkCard : _CreateListColors.lightCard;
    final borderColor = isDarkMode
        ? _CreateListColors.darkBorder
        : _CreateListColors.lightBorder;
    final labelColor = isDarkMode
        ? FreshSproutColors.darkTextMuted
        : const Color(0xFF64748B);
    final iconMuted = isDarkMode
        ? FreshSproutColors.darkTextMuted
        : const Color(0xFF94A3B8);

    return Container(
      clipBehavior: Clip.none,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(_CreateListSpec.cardRadius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.12 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NOME DA LISTA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: labelColor,
                    ),
              ),
              if (isListening) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _VoiceWaveIndicator(
                    color: accent,
                    soundLevelListenable: soundLevelListenable,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 20, color: iconMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSubmitted(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                  cursorColor: accent,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: 'Exemplo: compra do mês',
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: iconMuted,
                        ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  if (value.text.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return IconButton(
                    onPressed: onClear,
                    icon: Icon(Icons.close, size: 18, color: iconMuted),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
              _MicHoldButton(
                isDarkMode: isDarkMode,
                accent: accent,
                isMicHeld: isMicHeld,
                onPressStart: onMicPressStart,
                onPressEnd: onMicPressEnd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  const _SuggestionsSection({
    required this.isDarkMode,
    required this.accent,
    required this.suggestions,
    required this.onSelect,
  });

  final bool isDarkMode;
  final Color accent;
  final List<_Suggestion> suggestions;
  final ValueChanged<_Suggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    final labelColor = isDarkMode
        ? FreshSproutColors.darkTextMuted
        : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXEMPLOS RÁPIDOS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: labelColor,
                    ),
              ),
              Text(
                'Toque para aplicar',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 6,
          runSpacing: 6,
          children: suggestions.map((suggestion) {
            return _SuggestionChip(
              isDarkMode: isDarkMode,
              accent: accent,
              suggestion: suggestion,
              onTap: () => onSelect(suggestion),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.isDarkMode,
    required this.accent,
    required this.suggestion,
    required this.onTap,
  });

  final bool isDarkMode;
  final Color accent;
  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg =
        isDarkMode ? _CreateListColors.darkCard : _CreateListColors.lightCard;
    final border = isDarkMode
        ? _CreateListColors.darkBorder
        : _CreateListColors.lightBorder;
    final fg = isDarkMode
        ? FreshSproutColors.darkTextSecondary
        : const Color(0xFF334155);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_CreateListSpec.chipRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(_CreateListSpec.chipRadius),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(suggestion.emoji, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(
                  suggestion.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCardShell extends StatelessWidget {
  const _OptionCardShell({
    required this.isDarkMode,
    required this.child,
  });

  final bool isDarkMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cardBg =
        isDarkMode ? _CreateListColors.darkCard : _CreateListColors.lightCard;
    final border = isDarkMode
        ? _CreateListColors.darkBorder
        : _CreateListColors.lightBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(_CreateListSpec.cardRadius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.1 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmojiOptionButton extends StatelessWidget {
  const _EmojiOptionButton({
    required this.isDarkMode,
    required this.accent,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final bool isDarkMode;
  final Color accent;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = isDarkMode
        ? _CreateListColors.darkSurface
        : const Color(0xFFF1F5F9);
    final idleBorder = isDarkMode
        ? _CreateListColors.darkBorder.withValues(alpha: 0.5)
        : _CreateListColors.lightBorder;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: _CreateListSpec.emojiBtnSize,
          height: _CreateListSpec.emojiBtnSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? accent : idleBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}

class _EmojiCategoryCard extends StatelessWidget {
  const _EmojiCategoryCard({
    required this.isDarkMode,
    required this.accent,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final bool isDarkMode;
  final Color accent;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final accentTint = isDarkMode
        ? accent.withValues(alpha: 0.1)
        : _CreateListColors.brandEmerald.withValues(alpha: 0.1);

    return _OptionCardShell(
      isDarkMode: isDarkMode,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🏷️', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emoji / Categoria',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF1E293B),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Identifique sua lista com um ícone',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        height: 1.35,
                        color: isDarkMode
                            ? _CreateListColors.darkMuted
                            : const Color(0xFF64748B),
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: options.map((emoji) {
                    return _EmojiOptionButton(
                      isDarkMode: isDarkMode,
                      accent: accent,
                      emoji: emoji,
                      selected: emoji == selected,
                      onTap: () => onSelected(emoji),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.isDarkMode,
    required this.accent,
    required this.controller,
  });

  final bool isDarkMode;
  final Color accent;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final accentTint = isDarkMode
        ? accent.withValues(alpha: 0.1)
        : _CreateListColors.brandEmerald.withValues(alpha: 0.1);
    final fieldBg = isDarkMode
        ? _CreateListColors.darkSurface
        : const Color(0xFFF1F5F9);
    final fieldBorder = isDarkMode
        ? _CreateListColors.darkBorder.withValues(alpha: 0.6)
        : _CreateListColors.lightBorder;
    const fieldRadius = BorderRadius.all(Radius.circular(8));

    return _OptionCardShell(
      isDarkMode: isDarkMode,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('💵', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teto de Gastos (Opcional)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF1E293B),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Meta orçamentária para a compra',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        height: 1.35,
                        color: isDarkMode
                            ? _CreateListColors.darkMuted
                            : const Color(0xFF64748B),
                      ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  inputFormatters: [CurrencyInputFormatter()],
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF1E293B),
                      ),
                  cursorColor: accent,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: fieldBg,
                    hintText: 'R\$ 0,00',
                    hintStyle:
                        Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? _CreateListColors.darkMuted
                                  : const Color(0xFF94A3B8),
                            ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: fieldRadius,
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: fieldRadius,
                      borderSide: BorderSide(color: fieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: fieldRadius,
                      borderSide: BorderSide(color: fieldBorder),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MicHoldButton extends StatelessWidget {
  const _MicHoldButton({
    required this.isDarkMode,
    required this.accent,
    required this.isMicHeld,
    required this.onPressStart,
    required this.onPressEnd,
  });

  final bool isDarkMode;
  final Color accent;
  final bool isMicHeld;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  Widget build(BuildContext context) {
    final expanded = isMicHeld;
    final iconSize = expanded ? 30.0 : 18.0;
    final radius = expanded ? 22.0 : _CreateListSpec.chipRadius;
    final bg = expanded
        ? accent.withValues(alpha: isDarkMode ? 0.28 : 0.18)
        : (isDarkMode
            ? _CreateListColors.darkSurface
            : const Color(0xFFF1F5F9));
    final scale = expanded
        ? _CreateListSpec.micBtnSizeActive / _CreateListSpec.micBtnSize
        : 1.0;

    return SizedBox(
      width: _CreateListSpec.micBtnSize,
      height: _CreateListSpec.micBtnSize,
      child: Center(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => onPressStart(),
          onPointerUp: (_) => onPressEnd(),
          onPointerCancel: (_) => onPressEnd(),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Container(
              width: _CreateListSpec.micBtnSize,
              height: _CreateListSpec.micBtnSize,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: expanded
                      ? accent.withValues(alpha: 0.45)
                      : Colors.transparent,
                  width: expanded ? 1 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: expanded
                        ? accent.withValues(alpha: 0.35)
                        : Colors.transparent,
                    blurRadius: expanded ? 18 : 0,
                    spreadRadius: expanded ? 1 : 0,
                  ),
                ],
              ),
              child: Icon(
                expanded ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: iconSize,
                color: accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceWaveIndicator extends StatefulWidget {
  const _VoiceWaveIndicator({
    required this.color,
    required this.soundLevelListenable,
  });

  final Color color;
  final ValueListenable<double> soundLevelListenable;

  @override
  State<_VoiceWaveIndicator> createState() => _VoiceWaveIndicatorState();
}

class _VoiceWaveIndicatorState extends State<_VoiceWaveIndicator>
    with SingleTickerProviderStateMixin {
  static const _barCount = 14;

  late final AnimationController _phaseController;

  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _phaseController,
      builder: (context, _) {
        return ValueListenableBuilder<double>(
          valueListenable: widget.soundLevelListenable,
          builder: (context, soundLevel, _) {
            return SizedBox(
              height: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_barCount, (index) {
                  final wave = math.sin(
                    (index / _barCount * math.pi * 2) +
                        (_phaseController.value * math.pi * 2),
                  );
                  final levelBoost = 0.25 + (soundLevel * 0.75);
                  final height =
                      (3 + ((wave.abs() * 0.55) + 0.15) * 10 * levelBoost)
                          .clamp(2.0, 12.0);

                  return Padding(
                    padding:
                        EdgeInsets.only(right: index == _barCount - 1 ? 0 : 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      curve: Curves.easeOut,
                      width: 2,
                      height: height,
                      decoration: BoxDecoration(
                        color: widget.color
                            .withValues(alpha: 0.45 + (soundLevel * 0.55)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}

class _SubmitFooter extends StatelessWidget {
  const _SubmitFooter({
    required this.isDarkMode,
    required this.enabled,
    required this.isSaving,
    required this.onPressed,
  });

  final bool isDarkMode;
  final bool enabled;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bg = isDarkMode ? _CreateListColors.darkBg : _CreateListColors.lightBg;
    final btnBg = isDarkMode
        ? _CreateListColors.brandAmber
        : _CreateListColors.brandEmerald;
    final btnFg = isDarkMode ? const Color(0xFF020617) : Colors.white;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: (isDarkMode
                        ? _CreateListColors.darkBorder
                        : _CreateListColors.lightBorder)
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: enabled ? onPressed : null,
                  borderRadius: BorderRadius.circular(_CreateListSpec.cardRadius),
                  child: Ink(
                    height: 56,
                    decoration: BoxDecoration(
                      color: enabled
                          ? btnBg
                          : btnBg.withValues(alpha: 0.45),
                      borderRadius:
                          BorderRadius.circular(_CreateListSpec.cardRadius),
                      boxShadow: enabled
                          ? (isDarkMode
                              ? _CreateListColors.glowAmber(true)
                              : _CreateListColors.glowEmerald(true))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSaving)
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: btnFg,
                            ),
                          )
                        else ...[
                          Text(
                            'Continuar para os itens',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: btnFg,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.arrow_forward_rounded, color: btnFg),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
