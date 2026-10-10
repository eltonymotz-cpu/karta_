// =================================================================
// نصوص الكوينز (عربي + فرانكو)
// =================================================================
import 'texts.dart';

class CoinText {
  static const wallet = LText('المحفظة', 'El ma7faza');
  static const balances = LText('الأرصدة', 'El arsda');
  static const history = LText('العمليات', 'El 3amalyat');
  static const transfer = LText('تحويل', 'Ta7weel');
  static const challenges = LText('تحديات', 'Ta7addyat');
  static const adjust = LText('تعديل (الهوست)', 'Ta3deel (el host)');
  static const notice = LText(
    'الكوينز لعب بس ومالهاش أي قيمة حقيقية. كل لعبة بتبدأ برصيد جديد، وكل حاجة بتتمسح أول ما اللعبة تتقفل.',
    'El coins le3b bas w malhash ay 2eema 7a2e2ya. Kol le3ba btebda2 b raseed gedeed, w kol 7aga btetmese7 awel ma el le3ba tet2efel.',
  );
  static const off = LText('الكوينز مقفولة في اللعبة دي', 'El coins ma2foola fel le3ba di');
  static const frozen = LText('🧊 الأدمن مجمّد عمليات الكوينز دلوقتي', '🧊 El admin mgammed 3amalyat el coins');
  static const earned = LText('كسب', 'Kasab');
  static const spent = LText('صرف', 'Saraf');
  static const taxPaid = LText('ضرايب', 'Daraayeb');
  static const received = LText('استلم', 'Estalam');
  static const sent = LText('بعت', 'Ba3at');
  static const pot = LText('الحصالة', 'El 7assala');
  static const created = LText('اتعمل', 'Et3amal');
  static const burned = LText('اتحرق', 'Et7ara2');
  static const mine = LText('عملياتي بس', '3amalyaty bas');
  static const noTx = LText('مفيش عمليات لسه', 'Mafeesh 3amalyat lessa');
  static const from = LText('من', 'Men');
  static const to = LText('لـ', 'Le');
  static const amount = LText('المبلغ', 'El mablagh');
  static const fee = LText('رسوم', 'Rosoom');
  static const confirmTransfer = LText('تأكيد: {from} يبعت {amount} لـ {to}؟', 'Ta2keed: {from} yeb3at {amount} le {to}?');
  static const send = LText('ابعت', 'Eb3at');
  static const done = LText('تم ✔', 'Tamm ✔');
  static const limits = LText('من {min} لـ {max}', 'Men {min} le {max}');
  static const pickSeatFirst = LText('اختار إنت مين الأول (فوق)', 'Ekhtar enta meen el awel');
  static const opponent = LText('الخصم', 'El khasm');
  static const stake = LText('الرهان', 'El rehan');
  static const challengeRule = LText(
    'التحدي: الاتنين بيحطوا نفس الرهان، وأول واحد فيهم ياخد كارت يخسر الرهان كله للتاني. لو اللعبة خلصت ومحدش فيهم خد كارت، كل واحد بياخد رهانه.',
    'El ta7addy: el etneen by7otto nafs el rehan, w awel wa7ed fehom yakhod kart yekhsar el rehan kollo lel tany. Law el le3ba khelset w ma7adesh fehom khad kart, kol wa7ed byakhod rehano.',
  );
  static const sendChallenge = LText('ابعت التحدي', 'Eb3at el ta7addy');
  static const accept = LText('موافق', 'Mowafe2');
  static const decline = LText('مش موافق', 'Mesh mowafe2');
  static const cancel = LText('إلغاء', 'Elgha2');
  static const noChallenges = LText('مفيش تحديات', 'Mafeesh ta7addyat');
  static const statusPending = LText('مستني الرد', 'Mestanny el rad');
  static const statusActive = LText('شغال', 'Shaghal');
  static const statusWon = LText('{name} كسب', '{name} kesb');
  static const statusDeclined = LText('اترفض', 'Etrafad');
  static const statusCancelled = LText('اتلغى', 'Etlagha');
  static const statusExpired = LText('انتهى وقته', 'Entaha wa2to');
  static const statusRefunded = LText('الرهان رجع (تعادل)', 'El rehan rege3 (ta3adol)');
  static const player = LText('اللاعب', 'El la3eb');
  static const reason = LText('السبب (إجباري)', 'El sabab (egbary)');
  static const add = LText('ضيف', 'Dayef');
  static const subtract = LText('اخصم', 'Ekhsem');
  static const coinRanking = LText('ترتيب الكوينز', 'Tarteeb el coins');

  /// شرح سبب العملية
  static LText txReason(String code) => switch (code) {
        'start' => const LText('رصيد البداية', 'Raseed el bedaya'),
        'tax' => const LText('ضريبة خسارة', 'Dareebet khsara'),
        'taxShare' => const LText('نصيب من الضريبة', 'Naseeb men el dareeba'),
        'taxRefund' => const LText('رجوع ضريبة (تصحيح)', 'Rogoo3 dareeba (tas7ee7)'),
        'answered' => const LText('مكافأة: جاوب', 'Mokaf2a: gaweb'),
        'rewardRevoked' => const LText('إلغاء مكافأة', 'Elgha2 mokaf2a'),
        'nobodyLost' => const LText('مكافأة: محدش خسر', 'Mokaf2a: ma7adesh khesr'),
        'clapFirst' => const LText('مكافأة: أول واحد صقّف', 'Mokaf2a: awel wa7ed sa22af'),
        'gameWin' => const LText('مكافأة الكسبان', 'Mokaf2et el kasban'),
        'potWon' => const LText('الحصالة', 'El 7assala'),
        'transfer' => const LText('تحويل', 'Ta7weel'),
        'transferFee' => const LText('رسوم تحويل', 'Rosoom ta7weel'),
        'stake' => const LText('رهان تحدي', 'Rehan ta7addy'),
        'challengeWon' => const LText('كسب تحدي', 'Kasb ta7addy'),
        'challengeTie' => const LText('رجوع رهان (تعادل)', 'Rogoo3 rehan'),
        'adjust' => const LText('تعديل من الهوست', 'Ta3deel men el host'),
        _ => LText(code, code),
      };

  /// رسالة الخطأ
  static LText error(String code) => switch (code) {
        'self' => const LText('مينفعش تبعت لنفسك', 'Mayenfa3sh teb3at le nafsak'),
        'limits' => const LText('المبلغ برا الحدود المسموحة', 'El mablagh barra el 7odood'),
        'balance' => const LText('الرصيد مش كفاية', 'El raseed mesh kefaya'),
        'cooldown' => const LText('استنى شوية قبل التحويل الجاي', 'Estanna shwaya'),
        'tooMany' => const LText('وصلت لأقصى عدد تحويلات في اللعبة', 'Wesselt le a2sa 3adad ta7weelat'),
        'frozen' => const LText('العمليات متجمدة من الأدمن', 'El 3amalyat metgammeda'),
        'disabled' => const LText('الميزة دي مقفولة', 'El meeza di ma2foola'),
        'exists' => const LText('فيه تحدي مفتوح بينكم خلاص', 'Feeh ta7addy maftoo7 benkom'),
        'expired' => const LText('الدعوة انتهى وقتها', 'El da3wa entaha wa2t-ha'),
        'notYours' => const LText('ده مش اللاعب بتاعك', 'Da mesh el la3eb beta3ak'),
        'reason' => const LText('اكتب سبب التعديل', 'Ekteb sabab el ta3deel'),
        'timeout' => const LText('الهوست مردش، جرّب تاني', 'El host maraddesh, garrab tany'),
        _ => const LText('ماتمش', 'Matammesh'),
      };
}
