// =================================================================
// لوحة الأدمن: إعدادات الكوينز (نسخة لموبايل واحد ونسخة للأونلاين)
// -----------------------------------------------------------------
// - عام: تشغيل/قفل، اسم العملة وأيقونتها (من مكتبة الصور)، رصيد البداية والأقصى، تجميد العمليات
// - الضريبة: الطريقة (ثابتة/نسبة/نسبة بحد أدنى وأقصى)، نسبة خاصة لكل نوع كارت،
//   الضريبة رايحة فين، ولو الرصيد مش كفاية
// - المكافآت، التحويلات، التحديات
// - نسخ الإعدادات من وضع للتاني
// كل حاجة بتتراجع قبل الحفظ، والسيرفر بيرفض الحفظ لو الحساب مش أدمن،
// وكل تعديل بيتسجل في سجل الأدمن (مين وإمتى وقبل وبعد) - شوف migration 004.
// =================================================================
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../data/coin_texts.dart';
import '../data/texts.dart';
import '../game/economy.dart';
import '../game/game_controller.dart';
import '../services/app_settings.dart';
import '../theme.dart';
import '../widgets/card_face.dart';
import '../widgets/common.dart';
import 'asset_library_screen.dart';

class EconomySettingsScreen extends StatefulWidget {
  final GameController game;
  const EconomySettingsScreen({super.key, required this.game});

  @override
  State<EconomySettingsScreen> createState() => _EconomySettingsScreenState();
}

class _EconomySettingsScreenState extends State<EconomySettingsScreen> {
  GameController get game => widget.game;
  bool _online = false;
  late EconomyConfig _offline = AppSettings.current.economyOffline;
  late EconomyConfig _onlineCfg = AppSettings.current.economyOnline;
  bool _saving = false;
  late final _nameAr = TextEditingController(text: _cfg.name.ar);
  late final _nameFr = TextEditingController(text: _cfg.name.fr);

  EconomyConfig get _cfg => _online ? _onlineCfg : _offline;
  set _cfg(EconomyConfig value) => _online ? _onlineCfg = value : _offline = value;

  @override
  void dispose() {
    _nameAr.dispose();
    _nameFr.dispose();
    super.dispose();
  }

  void _set(String key, Object value) => setState(() => _cfg = _cfg.copyWith({key: value}));

  void _switchMode(bool online) {
    _syncName();
    setState(() => _online = online);
    _nameAr.text = _cfg.name.ar;
    _nameFr.text = _cfg.name.fr;
  }

  void _syncName() {
    final ar = _nameAr.text.trim(), fr = _nameFr.text.trim();
    _cfg = _cfg.copyWith({'name': LText(ar.isEmpty ? 'كوينز' : ar, fr.isEmpty ? 'Coins' : fr).toJson()});
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: error ? AppColors.red : AppColors.green,
    ));
  }

  Future<void> _save() async {
    _syncName();
    final problems = [..._offline.validate().map((p) => 'Offline: $p'), ..._onlineCfg.validate().map((p) => 'Online: $p')];
    if (problems.isNotEmpty) return _snack(problems.join(' • '), error: true);
    setState(() => _saving = true);
    final error = await AppSettings.save(AppSettings.current.copyWith(economyOffline: _offline, economyOnline: _onlineCfg));
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) return _snack(game.t(fillText(UiText.saveFailed, {'error': error})), error: true);
    _snack(game.t(UiText.saved));
  }

  // ---------------- عناصر ----------------
  Widget _section(String title, Color color, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: RetroWindow(
          title: title,
          barColor: color,
          child: Material(
            type: MaterialType.transparency,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      );

  Widget _switch(String label, String key, bool value) => SwitchListTile(
        value: value,
        onChanged: (v) => _set(key, v),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        activeThumbColor: AppColors.ink,
        activeTrackColor: AppColors.green,
        contentPadding: EdgeInsets.zero,
        dense: true,
      );

  /// رقم بحدوده (من EconomyConfig.ranges)
  Widget _number(String label, String key, int value) {
    final range = EconomyConfig.ranges[key]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          SizedBox(
            width: 110,
            child: TextFormField(
              key: ValueKey('$_online-$key'),
              initialValue: '$value',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (text) {
                final n = int.tryParse(text.trim());
                if (n != null) _set(key, n.clamp(range.$1, range.$2));
              },
              decoration: InputDecoration(
                isDense: true,
                helperText: '${range.$1}–${range.$2}',
                helperStyle: const TextStyle(fontSize: 9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Brutal.radius)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choice(String label, String key, String value, List<(String, LText)> options) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (v, text) in options)
                  ChoiceChip(label: Text(game.t(text)), selected: value == v, onSelected: (_) => _set(key, v)),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = _cfg;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                children: [
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      SquareButton(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.arrow_back, textDirection: TextDirection.ltr)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('🪙 ${game.t(EcoText.title)}', style: pixelStyle(size: 16), overflow: TextOverflow.ellipsis)),
                      LangToggle(game: game, compact: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(game.t(CoinText.notice), style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  // الوضع: موبايل واحد / أونلاين + النسخ من التاني
                  Row(
                    children: [
                      for (final online in [false, true])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: GestureDetector(
                              onTap: () => _switchMode(online),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: Brutal.box(
                                  color: _online == online ? AppColors.yellow : AppColors.paper,
                                  borderWidth: 2,
                                  shadowOffset: _online == online ? const Offset(2, 2) : Offset.zero,
                                ),
                                child: Text(game.t(online ? UiText.multiDevice : UiText.singleDevice), style: pixelStyle(size: 13)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      _syncName();
                      setState(() => _cfg = _online ? _offline : _onlineCfg);
                      _nameAr.text = _cfg.name.ar;
                      _nameFr.text = _cfg.name.fr;
                    },
                    child: Text(game.t(_online ? EcoText.copyFromOffline : EcoText.copyFromOnline)),
                  ),
                  const SizedBox(height: 6),
                  KeyedSubtree(
                    key: ValueKey(_online),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section('⚙ ${game.t(EcoText.general)}', AppColors.teal, [
                          _switch(game.t(EcoText.enabled), 'enabled', c.enabled),
                          _switch('🧊 ${game.t(EcoText.freeze)}', 'frozen', c.frozen),
                          TextField(controller: _nameAr, decoration: InputDecoration(labelText: game.t(EcoText.nameAr), isDense: true)),
                          TextField(controller: _nameFr, decoration: InputDecoration(labelText: game.t(EcoText.nameFr), isDense: true)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                padding: const EdgeInsets.all(4),
                                decoration: Brutal.box(borderWidth: 1.6, shadowOffset: Offset.zero),
                                child: imageFromRef(c.icon, fit: BoxFit.contain),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  final ref = await pickLibraryAsset(context, game);
                                  if (ref != null) _set('icon', ref);
                                },
                                child: Text(game.t(EcoText.pickIcon)),
                              ),
                            ],
                          ),
                          _number(game.t(EcoText.startBalance), 'startBalance', c.startBalance),
                          _number(game.t(EcoText.maxBalance), 'maxBalance', c.maxBalance),
                        ]),
                        _section('💸 ${game.t(EcoText.tax)}', AppColors.red, [
                          _switch(game.t(EcoText.taxEnabled), 'taxEnabled', c.taxEnabled),
                          Text(game.t(EcoText.taxWhen), style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          _choice(game.t(EcoText.taxMethod), 'taxMethod', c.taxMethod, [
                            ('fixed', EcoText.methodFixed),
                            ('percent', EcoText.methodPercent),
                            ('percentClamped', EcoText.methodClamped),
                          ]),
                          if (c.taxMethod == 'fixed') _number(game.t(EcoText.taxFixed), 'taxFixed', c.taxFixed),
                          if (c.taxMethod != 'fixed') _number(game.t(EcoText.taxPercent), 'taxPercent', c.taxPercent),
                          if (c.taxMethod == 'percentClamped') ...[
                            _number(game.t(EcoText.taxMin), 'taxMin', c.taxMin),
                            _number(game.t(EcoText.taxMax), 'taxMax', c.taxMax),
                          ],
                          if (c.taxMethod != 'fixed') ...[
                            const SizedBox(height: 6),
                            Text(game.t(EcoText.byCategory), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            for (final cat in const [('normal', 'عادي', 'Normal'), ('action', 'أكشن', 'Action'), ('queen', 'Q', 'Q'), ('bomb', 'قنبلة', 'Bomb')])
                              _categoryRow(cat.$1, LText(cat.$2, cat.$3), c),
                          ],
                          _choice(game.t(EcoText.destination), 'taxDestination', c.taxDestination, [
                            ('burn', EcoText.destBurn),
                            ('pot', EcoText.destPot),
                            ('others', EcoText.destOthers),
                            ('turnPlayer', EcoText.destTurn),
                          ]),
                          _choice(game.t(EcoText.insufficient), 'insufficient', c.insufficient, [
                            ('takeAll', EcoText.takeAll),
                            ('skip', EcoText.skipTax),
                          ]),
                          Text(game.t(EcoText.noNegative), style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        ]),
                        _section('🎁 ${game.t(EcoText.rewards)}', AppColors.green, [
                          _number(game.t(EcoText.rewardGameWin), 'rewardGameWin', c.rewardGameWin),
                          _number(game.t(EcoText.rewardAnswered), 'rewardAnswered', c.rewardAnswered),
                          _number(game.t(EcoText.rewardNobodyLost), 'rewardNobodyLost', c.rewardNobodyLost),
                          _number(game.t(EcoText.rewardClapFirst), 'rewardClapFirst', c.rewardClapFirst),
                          Text(game.t(EcoText.zeroOff), style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        ]),
                        _section('🔁 ${game.t(CoinText.transfer)}', AppColors.blue, [
                          _switch(game.t(EcoText.enabled), 'transferEnabled', c.transferEnabled),
                          _number(game.t(EcoText.min), 'transferMin', c.transferMin),
                          _number(game.t(EcoText.max), 'transferMax', c.transferMax),
                          _number(game.t(EcoText.feePercent), 'transferFeePercent', c.transferFeePercent),
                          _number(game.t(EcoText.cooldown), 'transferCooldownSec', c.transferCooldownSec),
                          _number(game.t(EcoText.perGame), 'transferMaxPerGame', c.transferMaxPerGame),
                          Text(game.t(EcoText.transferScope), style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        ]),
                        _section('⚔ ${game.t(CoinText.challenges)}', AppColors.orange, [
                          _switch(game.t(EcoText.enabled), 'challengeEnabled', c.challengeEnabled),
                          Text(game.t(CoinText.challengeRule), style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          _number(game.t(EcoText.stakeMin), 'stakeMin', c.stakeMin),
                          _number(game.t(EcoText.stakeMax), 'stakeMax', c.stakeMax),
                          _number(game.t(EcoText.feePercent), 'challengeFeePercent', c.challengeFeePercent),
                          _number(game.t(EcoText.inviteTimeout), 'inviteTimeoutSec', c.inviteTimeoutSec),
                        ]),
                      ],
                    ),
                  ),
                  _saving
                      ? Center(child: CircularProgressIndicator(color: AppColors.ink))
                      : BrutalButton(label: game.t(UiText.save), onTap: _save),
                  const SizedBox(height: 20),
                  _AuditLog(game: game),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// نسبة ضريبة خاصة لنوع كارت (فاضي = النسبة العامة)
  Widget _categoryRow(String key, LText label, EconomyConfig c) {
    final current = c.taxByCategory[key];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(game.t(label), style: const TextStyle(fontSize: 13))),
          SizedBox(
            width: 110,
            child: TextFormField(
              key: ValueKey('$_online-cat-$key'),
              initialValue: current?.toString() ?? '',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(isDense: true, hintText: '${c.taxPercent}%', border: OutlineInputBorder(borderRadius: BorderRadius.circular(Brutal.radius))),
              onChanged: (text) {
                final map = Map<String, int>.from(c.taxByCategory);
                final n = int.tryParse(text.trim());
                if (n == null) {
                  map.remove(key);
                } else {
                  map[key] = n.clamp(0, 100);
                }
                setState(() => _cfg = _cfg.copyWith({'taxByCategory': map}));
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// سجل تعديلات الأدمن (مين غيّر إيه وإمتى، قبل وبعد) - بيتقري من Supabase
class _AuditLog extends StatefulWidget {
  final GameController game;
  const _AuditLog({required this.game});

  @override
  State<_AuditLog> createState() => _AuditLogState();
}

class _AuditLogState extends State<_AuditLog> {
  List<Map<String, dynamic>>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppConfig.hasSupabase) return;
    try {
      final rows = await Supabase.instance.client.from('karta_admin_audit').select('admin_email, changed_at, changes').order('changed_at', ascending: false).limit(20);
      if (mounted) setState(() => _rows = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().contains('karta_admin_audit') ? 'Run supabase/migrations/004_admin_audit.sql' : '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return RetroWindow(
      title: '📜 ${game.t(EcoText.audit)}',
      barColor: AppColors.purple,
      child: _error != null
          ? Text('⚠ $_error', style: TextStyle(fontSize: 12, color: AppColors.red))
          : _rows == null
              ? const SizedBox(height: 30, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : _rows!.isEmpty
                  ? Text(game.t(CoinText.noTx), style: TextStyle(color: AppColors.muted))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final r in _rows!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${(r['changed_at'] as String? ?? '').replaceFirst('T', ' ').split('.').first} • ${r['admin_email'] ?? '?'}\n${r['changes'] ?? ''}',
                              style: TextStyle(fontSize: 11, color: AppColors.ink),
                            ),
                          ),
                      ],
                    ),
    );
  }
}

/// نصوص لوحة الكوينز
class EcoText {
  static const title = LText('إعدادات الكوينز', 'E3dadat el coins');
  static const copyFromOffline = LText('انسخ إعدادات موبايل واحد هنا', 'Ensakh e3dadat mobile wa7ed hena');
  static const copyFromOnline = LText('انسخ إعدادات الأونلاين هنا', 'Ensakh e3dadat el online hena');
  static const general = LText('عام', '3am');
  static const enabled = LText('مفعّل', 'Mfa33al');
  static const freeze = LText('تجميد كل العمليات (تحويلات/تحديات/تعديلات)', 'Tagmeed kol el 3amalyat');
  static const nameAr = LText('اسم العملة (عربي)', 'Esm el 3omla (3araby)');
  static const nameFr = LText('اسم العملة (فرانكو)', 'Esm el 3omla (Franco)');
  static const pickIcon = LText('🖼 أيقونة العملة من المكتبة', '🖼 Ay2onet el 3omla');
  static const startBalance = LText('رصيد البداية', 'Raseed el bedaya');
  static const maxBalance = LText('أقصى رصيد', 'A2sa raseed');
  static const tax = LText('ضريبة الخسارة', 'Dareebet el khsara');
  static const taxEnabled = LText('الضريبة شغالة', 'El dareeba shaghala');
  static const taxWhen = LText(
    'الخسران = اللي بياخد الكارت (أو اللي كلّم الصامت). كل كارت بيتحسب مرة واحدة بس.',
    'El khasran = elly byakhod el kart (aw elly kallem el samet). Kol kart byet7seb marra wa7da bas.',
  );
  static const taxMethod = LText('طريقة الحساب', 'Taree2et el 7esab');
  static const methodFixed = LText('مبلغ ثابت', 'Mablagh sabet');
  static const methodPercent = LText('نسبة من الرصيد', 'Nesba men el raseed');
  static const methodClamped = LText('نسبة بحد أدنى وأقصى', 'Nesba b 7ad adna w a2sa');
  static const taxFixed = LText('المبلغ الثابت', 'El mablagh el sabet');
  static const taxPercent = LText('النسبة %', 'El nesba %');
  static const taxMin = LText('أقل ضريبة', 'A2al dareeba');
  static const taxMax = LText('أقصى ضريبة', 'A2sa dareeba');
  static const byCategory = LText('نسبة خاصة لكل نوع كارت (فاضي = النسبة العامة)', 'Nesba khassa le kol no3 kart');
  static const destination = LText('الضريبة رايحة فين؟', 'El dareeba ray7a fen?');
  static const destBurn = LText('تتحرق (تخرج من اللعبة)', 'Tet7ere2');
  static const destPot = LText('حصالة للكسبان في الآخر', '7assala lel kasban');
  static const destOthers = LText('تتوزع على الباقيين', 'Tetwazza3 3al ba2yeen');
  static const destTurn = LText('لصاحب الدور', 'Le sa7eb el dor');
  static const insufficient = LText('لو الرصيد مش كفاية', 'Law el raseed mesh kefaya');
  static const takeAll = LText('ياخد اللي معاه', 'Yakhod elly ma3ah');
  static const skipTax = LText('مايدفعش', 'Mayedfa3sh');
  static const noNegative = LText('مفيش رصيد بالسالب أبداً، واللاعب يقدر يكمّل برصيد صفر.', 'Mafeesh raseed bel saleb abadan.');
  static const rewards = LText('المكافآت', 'El mokaf2at');
  static const rewardGameWin = LText('الكسبان في آخر اللعبة (الأقل كروت)', 'El kasban fel akher');
  static const rewardAnswered = LText('صاحب الدور جاوب (الهوست بيسجل)', 'Sa7eb el dor gaweb');
  static const rewardNobodyLost = LText('محدش خسر (لصاحب الدور)', 'Ma7adesh khesr');
  static const rewardClapFirst = LText('أول واحد صقّف', 'Awel wa7ed sa22af');
  static const zeroOff = LText('0 = المكافأة مقفولة', '0 = el mokaf2a ma2foola');
  static const min = LText('أقل مبلغ', 'A2al mablagh');
  static const max = LText('أقصى مبلغ', 'A2sa mablagh');
  static const feePercent = LText('رسوم %', 'Rosoom %');
  static const cooldown = LText('ثواني بين كل تحويل', 'Sawany ben kol ta7weel');
  static const perGame = LText('أقصى تحويلات للاعب في اللعبة', 'A2sa ta7weelat fel le3ba');
  static const transferScope = LText(
    'التحويل بين اللاعيبة اللي في نفس اللعبة بس، والطلب لازم يكون من موبايل اللاعب نفسه (أو الهوست على موبايل واحد).',
    'El ta7weel ben la3eebet nafs el le3ba bas.',
  );
  static const stakeMin = LText('أقل رهان', 'A2al rehan');
  static const stakeMax = LText('أقصى رهان', 'A2sa rehan');
  static const inviteTimeout = LText('مهلة الرد على الدعوة (ثانية)', 'Mohlet el rad (sanya)');
  static const audit = LText('سجل تعديلات الأدمن', 'Segel ta3deelat el admin');
}
