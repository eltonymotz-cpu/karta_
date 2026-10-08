// =================================================================
// الشاشة الأولى: موبايل واحد ولا أكتر من موبايل؟
// -----------------------------------------------------------------
// 🔒 مدخل الأدمن المخفي: دوس على اللوجو 5 مرات ورا بعض (في خلال ثانيتين)
//    وبعدين اكتب الرقم السري (موجود في lib/config.dart)
// =================================================================
import 'package:flutter/material.dart';

import '../config.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  final GameController game;
  const HomeScreen({super.key, required this.game});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _codeController = TextEditingController();
  int _logoTaps = 0;              // عدد الضغطات على اللوجو
  DateTime _firstTap = DateTime(2000);

  GameController get game => widget.game;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// الضغط على اللوجو: 5 ضغطات بسرعة = لوحة الأدمن
  void _onLogoTap() {
    final now = DateTime.now();
    if (now.difference(_firstTap).inSeconds >= 2) {
      _firstTap = now; // نبدأ العد من الأول
      _logoTaps = 0;
    }
    _logoTaps++;
    if (_logoTaps >= 5) {
      _logoTaps = 0;
      _askPin();
    }
  }

  /// نافذة الرقم السري
  Future<void> _askPin() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: BrutalBox(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Headline('🔒 ${game.t(UiText.adminPinTitle)}', size: 24),
              const SizedBox(height: 14),
              _BoxField(
                controller: controller,
                hint: '••••',
                obscure: true,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => Navigator.pop(context, controller.text == AppConfig.adminPin),
              ),
              const SizedBox(height: 16),
              BrutalButton(
                label: game.t(UiText.join),
                onTap: () => Navigator.pop(context, controller.text == AppConfig.adminPin),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (!mounted || ok == null) return;
    if (ok) {
      game.openAdmin();
    } else {
      _snack(game.t(UiText.wrongPin));
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)), backgroundColor: AppColors.red),
    );
  }

  void _multi() {
    if (!AppConfig.hasSupabase) return _snack(game.t(UiText.noSupabase));
    game.chooseMultiDevice();
  }

  void _join() {
    if (!AppConfig.hasSupabase) return _snack(game.t(UiText.noSupabase));
    if (_codeController.text.trim().length < 4) return;
    game.joinRoom(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        Row(
                          textDirection: TextDirection.ltr,
                          children: [LangToggle(game: game), const Spacer(), const ShapeAccent(size: 12)],
                        ),
                        const SizedBox(height: 16),
                        // اللوجو (ومدخل الأدمن المخفي)
                        GestureDetector(
                          onTap: _onLogoTap,
                          child: Container(
                            height: 200,
                            padding: const EdgeInsets.all(10),
                            decoration: Brutal.box(shadowOffset: const Offset(6, 6)),
                            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Headline(game.t(UiText.homeTitle), size: 40),
                        const SizedBox(height: 6),
                        Text(game.t(UiText.homeSubtitle),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 20),
                        _option(
                          emoji: '📱',
                          title: game.t(UiText.singleDevice),
                          description: game.t(UiText.singleDeviceDesc),
                          color: AppColors.yellow,
                          onTap: game.chooseSingleDevice,
                        ),
                        const SizedBox(height: 16),
                        _option(
                          emoji: '📲',
                          title: game.t(UiText.multiDevice),
                          description: game.t(UiText.multiDeviceDesc),
                          color: AppColors.paper,
                          onTap: _multi,
                        ),
                        const SizedBox(height: 28),
                        _joinBox(),
                      ],
                    ),
                  ),
                ),
              ),
              const ShapesStrip(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// اختيار طريقة لعب: مربع إيموجي + العنوان والوصف + سهم
  Widget _option({
    required String emoji,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: Brutal.box(color: color),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // الإيموجي في دايرة (زي صور البروفايل في التصميم)
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color == AppColors.yellow ? AppColors.paper : AppColors.yellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: FittedBox(child: Padding(padding: const EdgeInsets.all(6), child: Text(emoji, style: const TextStyle(fontSize: 24)))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                            Text(description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // سهم في دايرة سودا
              Center(
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsetsDirectional.only(end: 14),
                  decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                  // arrow_forward بيتقلب لوحده في العربي
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// صندوق الدخول بكود قعدة
  Widget _joinBox() {
    return BrutalBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(game.t(UiText.joinTitle).toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BoxField(
                  controller: _codeController,
                  hint: game.t(UiText.joinHint),
                  capital: true,
                  onSubmitted: (_) => _join(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: BrutalButton(label: game.t(UiText.join), onTap: _join, showArrow: false, height: 52, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// خانة كتابة بحدود سودا
class _BoxField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool capital;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  const _BoxField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.capital = false,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: capital ? TextCapitalization.characters : TextCapitalization.none,
      textAlign: TextAlign.center,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15, letterSpacing: 0),
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Brutal.radius),
          borderSide: const BorderSide(color: AppColors.ink, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Brutal.radius),
          borderSide: const BorderSide(color: AppColors.ink, width: 3),
        ),
      ),
    );
  }
}
