// =================================================================
// الشاشة الأولى: موبايل واحد ولا أكتر من موبايل؟
// -----------------------------------------------------------------
// 🔒 مدخل الأدمن المخفي: دوس على اللوجو 5 مرات ورا بعض (في خلال ثانيتين)
//    وبعدين سجّل دخول بحساب الأدمن (Supabase). لو Supabase مش متظبط،
//    بيطلب الرقم السري اللي في lib/config.dart (للتجربة على جهاز واحد بس).
// ❓ زرار المساعدة فوق: بيفتح صفحة "إزاي نلعب كارتة".
// =================================================================
import 'package:flutter/material.dart';

import '../config.dart';
import '../data/texts.dart';
import '../game/game_controller.dart';
import '../services/admin_auth.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'help_screen.dart';

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
      _openAdmin();
    }
  }

  /// فتح لوحة الأدمن: لو داخل كأدمن على طول، وإلا تسجيل دخول
  Future<void> _openAdmin() async {
    if (!AdminAuth.available) return _askPin(); // من غير Supabase: الرقم السري (جهاز واحد بس)
    if (AdminAuth.isLoggedIn && await AdminAuth.checkIsAdmin()) {
      game.openAdmin();
      return;
    }
    if (!mounted) return;
    final email = TextEditingController();
    final password = TextEditingController();
    String? error;
    bool loading = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            setDialogState(() {
              loading = true;
              error = null;
            });
            final result = await AdminAuth.signIn(email.text, password.text);
            if (!context.mounted) return;
            if (result == null) {
              Navigator.pop(context, true);
            } else {
              setDialogState(() {
                loading = false;
                error = result;
              });
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: RetroWindow(
              title: '🔒 ${game.t(UiText.adminLogin)}',
              barColor: AppColors.purple,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BoxField(controller: email, hint: game.t(UiText.email), keyboardType: TextInputType.emailAddress, small: true),
                  const SizedBox(height: 10),
                  _BoxField(
                    controller: password,
                    hint: game.t(UiText.password),
                    obscure: true,
                    small: true,
                    onSubmitted: (_) => submit(),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
                      : BrutalButton(label: game.t(UiText.login), onTap: submit),
                ],
              ),
            ),
          );
        },
      ),
    );
    email.dispose();
    password.dispose();
    if (ok == true && mounted) game.openAdmin();
  }

  /// نافذة الرقم السري (لما Supabase مش متظبط)
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
                          children: [
                            LangToggle(game: game),
                            const Spacer(),
                            // زرار المساعدة: إزاي نلعب كارتة
                            SquareButton(
                              color: AppColors.yellow,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => HelpScreen(game: game)),
                              ),
                              child: Text('?', style: pixelStyle(size: 20)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // اللوجو (ومدخل الأدمن المخفي)
                        GestureDetector(
                          onTap: _onLogoTap,
                          child: Container(
                            height: 200,
                            padding: const EdgeInsets.all(10),
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
                          color: AppColors.teal,
                          onTap: game.chooseSingleDevice,
                        ),
                        const SizedBox(height: 16),
                        _option(
                          emoji: '📲',
                          title: game.t(UiText.multiDevice),
                          description: game.t(UiText.multiDeviceDesc),
                          color: AppColors.orange,
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
    // شباك كمبيوتر قديم: شريط عنوان ملون + المحتوى
    return GestureDetector(
      onTap: onTap,
      child: RetroWindow(
        title: title,
        barColor: color,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // الإيموجي في مربع
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: Brutal.box(color: AppColors.bg, borderWidth: 2, shadowOffset: Offset.zero),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            // سهم في مربع غامق (arrow_forward بيتقلب لوحده في العربي)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.arrow_forward_rounded, color: AppColors.paper, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  /// صندوق الدخول بكود قعدة
  Widget _joinBox() {
    return RetroWindow(
      title: game.t(UiText.joinTitle),
      barColor: AppColors.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
  final bool small; // خط عادي (للإيميل والباسورد) بدل الخط الكبير بتاع الكود
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  const _BoxField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.capital = false,
    this.small = false,
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
      style: small
          ? const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)
          : const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4),
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
