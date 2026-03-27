import '../models/astro_models.dart';
import '../models/subscription_models.dart';
import 'contracts.dart';

class MockAstroProvider implements AstroProvider {
  static const Map<String, String> _horoscopeTemplates = <String, String>{
    'Aries':
        'Momentum builds when you commit early and avoid scattered effort.',
    'Taurus':
        'Steady planning beats urgency; lock one decision before evening.',
    'Gemini':
        'Conversations bring an opportunity if you keep the ask specific.',
    'Cancer': 'Home and routine choices create better emotional balance today.',
    'Leo': 'Visibility is high; lead with clarity, not speed.',
    'Virgo': 'A small process fix saves you time through the week.',
    'Libra': 'Partnerships improve when expectations are made explicit.',
    'Scorpio': 'Quiet focus helps you close a task others have delayed.',
    'Sagittarius': 'Learning something practical unlocks faster progress.',
    'Capricorn': 'Consistency matters more than intensity today.',
    'Aquarius': 'Try a different approach on one blocked problem.',
    'Pisces': 'Protect your energy and prioritize only what is measurable.',
  };

  @override
  Future<KundliData> getKundli(BirthDetails birthDetails) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return KundliData(
      sunSign: birthDetails.zodiacSign,
      moonSign: 'Cancer',
      ascendant: 'Libra',
      focusArea: 'Career alignment and communication timing.',
    );
  }

  @override
  Future<CompatibilityResult> getCompatibility(
    CompatibilityRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final int seed =
        request.primary.zodiacSign.codeUnitAt(0) +
        request.partner.zodiacSign.codeUnitAt(0);
    final int score = 62 + (seed % 34);
    return CompatibilityResult(
      score: score,
      summary:
          'You both align best when plans are discussed early and revisited weekly.',
      strengths: const <String>[
        'Reliable communication rhythm',
        'Good long-term planning chemistry',
        'Balanced emotional expectations',
      ],
    );
  }

  @override
  Future<NumerologyResult> getNumerology(BirthDetails birthDetails) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final List<int> digits = birthDetails.dateTime
        .toIso8601String()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .split('')
        .map(int.parse)
        .toList();
    final int total = digits.fold<int>(0, (int a, int b) => a + b);
    final int lifePath = _singleDigit(total);
    final int personalDay = _singleDigit(
      birthDetails.dateTime.day + DateTime.now().day + DateTime.now().month,
    );
    return NumerologyResult(
      lifePathNumber: lifePath,
      personalDayNumber: personalDay,
      guidance:
          'Focus on one concrete outcome today. Keep scope tight and track completion.',
    );
  }

  @override
  Future<HoroscopeResponse> getDailyHoroscope(
    DailyHoroscopeRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final String base =
        _horoscopeTemplates[request.zodiacSign] ??
        'Prioritize clarity and avoid reactive decisions today.';
    final String localizedSummary = _localizeSummary(base, request.locale);

    return HoroscopeResponse(
      date: request.date,
      zodiacSign: request.zodiacSign,
      locale: request.locale,
      summary: localizedSummary,
      luckyColor: 'Emerald Green',
      luckyNumber: request.date.day % 9 + 1,
    );
  }

  int _singleDigit(int value) {
    int n = value;
    while (n > 9) {
      n = n
          .toString()
          .split('')
          .map(int.parse)
          .fold<int>(0, (int a, int b) => a + b);
    }
    return n;
  }

  String _localizeSummary(String base, String locale) {
    if (locale.startsWith('hi')) {
      return 'आज का संकेत: $base';
    }
    if (locale.startsWith('bn')) {
      return 'আজকের ইঙ্গিত: $base';
    }
    return base;
  }
}

class RuleBasedGemstoneEngine implements GemstoneEngine {
  @override
  Future<GemstoneReport> buildReport(KundliData kundliData) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final String primaryStone = switch (kundliData.ascendant) {
      'Aries' => 'Red Coral',
      'Taurus' => 'Diamond',
      'Gemini' => 'Emerald',
      'Cancer' => 'Pearl',
      'Leo' => 'Ruby',
      'Virgo' => 'Emerald',
      'Libra' => 'Diamond',
      'Scorpio' => 'Red Coral',
      'Sagittarius' => 'Yellow Sapphire',
      'Capricorn' => 'Blue Sapphire',
      'Aquarius' => 'Amethyst',
      'Pisces' => 'Yellow Sapphire',
      _ => 'Emerald',
    };

    return GemstoneReport(
      primaryStone: primaryStone,
      alternativeStones: const <String>['Moonstone', 'Citrine'],
      rationale:
          'Selected by ascendant and current focus area to improve stability and decision quality.',
    );
  }
}

class LocalTemplateAiPersonalizer implements AiPersonalizer {
  @override
  Future<String> summarizeReport(
    GemstoneReport report, {
    required String locale,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (locale.startsWith('hi')) {
      return 'मुख्य रत्न ${report.primaryStone} है। इसे निरंतरता और स्पष्ट निर्णयों के लिए सुझाया गया है।';
    }
    if (locale.startsWith('bn')) {
      return 'প্রধান রত্ন ${report.primaryStone}। স্থিরতা এবং পরিষ্কার সিদ্ধান্তে এটি সহায়ক।';
    }
    return 'Primary recommendation is ${report.primaryStone}. It supports steadier execution and clearer decision making.';
  }

  @override
  Future<List<String>> generateDosDonts(
    HoroscopeResponse horoscope, {
    required String locale,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    if (locale.startsWith('hi')) {
      return const <String>[
        'करें: दिन के पहले हिस्से में सबसे महत्वपूर्ण काम पूरा करें।',
        'करें: एक जरूरी बातचीत को स्पष्ट और संक्षिप्त रखें।',
        'न करें: अधूरी जानकारी पर आर्थिक निर्णय न लें।',
        'न करें: कम प्रभाव वाले कामों पर समय बर्बाद न करें।',
      ];
    }
    if (locale.startsWith('bn')) {
      return const <String>[
        'করুন: দিনের প্রথম ভাগে সবচেয়ে গুরুত্বপূর্ণ কাজ শেষ করুন।',
        'করুন: গুরুত্বপূর্ণ আলোচনা সংক্ষিপ্ত ও স্পষ্ট রাখুন।',
        'করবেন না: অসম্পূর্ণ তথ্য নিয়ে আর্থিক সিদ্ধান্ত নেবেন না।',
        'করবেন না: কম প্রভাবের কাজে অতিরিক্ত সময় দেবেন না।',
      ];
    }
    return const <String>[
      'Do: Finish your highest-impact task before noon.',
      'Do: Keep one important conversation concise and explicit.',
      "Don't: Make financial commitments without full context.",
      "Don't: Overbook your evening with low-priority tasks.",
    ];
  }
}

class MockBillingGateway implements BillingGateway {
  SubscriptionEntitlement _entitlement = const SubscriptionEntitlement(
    tier: SubscriptionTier.free,
  );

  @override
  Future<void> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<SubscriptionEntitlement> syncEntitlement() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _entitlement;
  }

  @override
  Future<PurchaseStatus> startPurchase(PlanType planType) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final DateTime expiry = switch (planType) {
      PlanType.monthly => DateTime.now().add(const Duration(days: 30)),
      PlanType.yearly => DateTime.now().add(const Duration(days: 365)),
    };
    _entitlement = SubscriptionEntitlement(
      tier: SubscriptionTier.premium,
      expiresAt: expiry,
    );
    return PurchaseStatus.success;
  }
}
