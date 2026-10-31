import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/models/analysis_record.dart';
import 'package:scamshield_guardian/screens/results/analysis_result_screen.dart';

final _scamAnalysis = AnalysisRecord(
  id: 1,
  content: 'You have won a prize of 50,000! Click here: http://bit.ly/claim',
  riskScore: 86,
  riskLevel: 'HIGH',
  classification: 'SCAM',
  category: 'prize_claim',
  inputType: 'text',
  createdAt: DateTime.utc(2026, 10, 26, 11, 36),
  explanation: 'This message is likely a scam. It contains suspicious links and common prize scam patterns.',
  recommendedAction: 'Do not click links. Block and report sender.',
  mlProbability: 0.94,
  llmConfidence: 0.94,
  indicators: ['Prize Claim', 'Urgent Action', 'Shortened Link'],
  actionTranslations: {
    'en': [
      'Do not click on any links in this message.',
      'Do not share personal or banking details.',
      'Block and report the sender.',
      'Verify the information from official sources.',
    ],
    'hi': [
      'इस संदेश में किसी भी लिंक पर क्लिक न करें।',
      'व्यक्तिगत या बैंकिंग विवरण साझा न करें।',
      'प्रेषक को ब्लॉक करें और रिपोर्ट करें।',
      'आधिकारिक स्रोतों से जानकारी सत्यापित करें।',
    ],
    'te': [
      'ఈ లింక్‌పై క్లిక్ చేయవద్దు.',
      'మీ వ్యక్తిగత సమాచారం, OTP లేదా బ్యాంక్ వివరాలు పంచుకోవద్దు.',
      'సందేశం నిజమా కాదు అని అధికారిక వనరుల ద్వారా ధృవీకరించండి.',
      'ఇలాంటి సందేశాలను రిపోర్ట్ చేసి, పంపిన వ్యక్తిని బ్లాక్ చేయండి.',
    ],
  },
  safeActions: [
    'Do not click on any links in this message.',
    'Do not share personal or banking details.',
    'Block and report the sender.',
    'Verify the information from official sources.',
  ],
);

final _safeAnalysis = AnalysisRecord(
  id: 2,
  content: 'Your doctor appointment is confirmed for tomorrow at 10 AM.',
  riskScore: 8,
  riskLevel: 'LOW',
  classification: 'SAFE',
  category: 'general_informational',
  inputType: 'text',
  createdAt: DateTime.utc(2026, 10, 26, 10, 0),
  explanation: 'This message appears to be genuine. No suspicious links, patterns or scam indicators were found.',
  recommendedAction: 'This message is safe to interact with.',
  mlProbability: 0.92,
  llmConfidence: 0.92,
  indicators: [],
  actionTranslations: {
    'en': [
      'This message is safe to interact with.',
      'You can proceed if you trust the sender.',
      'Always stay cautious with unknown messages.',
      'Do not share sensitive information.',
    ],
    'hi': [
      'यह संदेश बातचीत के लिए सुरक्षित है।',
      'यदि आप प्रेषक पर भरोसा करते हैं तो आगे बढ़ सकते हैं।',
      'अज्ञात संदेशों के साथ हमेशा सतर्क रहें।',
      'संवेदनशील जानकारी साझा न करें।',
    ],
    'te': [
      'ఈ సందేశంతో పరస్పర చర్య చేయడం సురక్షితం.',
      'మీరు పంపినవారిని విశ్వసిస్తే కొనసాగవచ్చు.',
      'తెలియని సందేశాలతో ఎల్లప్పుడూ జాగ్రత్తగా ఉండండి.',
      'సున్నితమైన సమాచారాన్ని పంచుకోవద్దు.',
    ],
  },
  safeActions: [
    'This message is safe to interact with.',
    'You can proceed if you trust the sender.',
    'Always stay cautious with unknown messages.',
    'Do not share sensitive information.',
  ],
);

void main() {
  testWidgets('renders Scam Detected outcome with authoritative fields matching design reference', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AnalysisResultScreen(analysis: _scamAnalysis)),
    );

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.text('Scam Detected'), findsOneWidget);
    expect(find.text('This message shows multiple scam indicators.'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(
      find.text('This message is likely a scam. It contains suspicious links and common prize scam patterns.'),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Text Message'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);
    expect(find.text('1 Suspicious Link'), findsOneWidget);
    expect(find.text('Prize Claim, Urgent Action, Shortened Link'), findsOneWidget);

    await tester.ensureVisible(find.text('Recommendation'));
    expect(find.text('Recommendation'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिंदी'), findsOneWidget);
    expect(find.text('తెలుగు'), findsOneWidget);
    expect(find.text('Do not click on any links in this message.'), findsOneWidget);

    await tester.ensureVisible(find.text('Analyze Another'));
    expect(find.text('Analyze Another'), findsOneWidget);
    expect(find.text('Save to History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders Safe outcome with authoritative classification and green styling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AnalysisResultScreen(analysis: _safeAnalysis)),
    );

    expect(find.text('Safe'), findsOneWidget);
    expect(find.text('No known scam indicators were detected.'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('None detected'), findsOneWidget);
    expect(find.text('Normal / Legitimate'), findsOneWidget);
    expect(find.text('Why Not Flagged'), findsOneWidget);
    expect(find.text('This message is safe to interact with.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches recommendations to Hindi and Telugu with authentic script rendering', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AnalysisResultScreen(analysis: _scamAnalysis)),
    );

    // Initial English
    await tester.ensureVisible(find.text('Do not click on any links in this message.'));
    expect(find.text('Do not click on any links in this message.'), findsOneWidget);

    // Tap Hindi
    await tester.ensureVisible(find.text('हिंदी'));
    await tester.tap(find.text('हिंदी'));
    await tester.pumpAndSettle();
    expect(find.text('इस संदेश में किसी भी लिंक पर क्लिक न करें।'), findsOneWidget);

    // Tap Telugu
    await tester.ensureVisible(find.text('తెలుగు'));
    await tester.tap(find.text('తెలుగు'));
    await tester.pumpAndSettle();
    expect(find.text('ఈ లింక్‌పై క్లిక్ చేయవద్దు.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles missing translation honestly without fabricating text', (
    tester,
  ) async {
    final recordWithoutTranslations = AnalysisRecord(
      id: 3,
      content: 'Hello, your package is delayed.',
      riskScore: 40,
      riskLevel: 'MEDIUM',
      classification: 'SUSPICIOUS',
      category: 'delivery_notice',
      inputType: 'text',
      createdAt: DateTime.utc(2026, 10, 26),
      explanation: 'Unverified delivery claim from unknown sender.',
      actionTranslations: const {}, // No localized translations
      safeActions: const ['Verify tracking number on the official carrier site.'],
    );

    await tester.pumpWidget(
      MaterialApp(home: AnalysisResultScreen(analysis: recordWithoutTranslations)),
    );

    expect(find.text('Caution Advised'), findsOneWidget);

    await tester.ensureVisible(find.text('Verify tracking number on the official carrier site.'));
    expect(find.text('Verify tracking number on the official carrier site.'), findsOneWidget);

    // Tap Telugu when translation is missing
    await tester.ensureVisible(find.text('తెలుగు'));
    await tester.tap(find.text('తెలుగు'));
    await tester.pumpAndSettle();

    // Must display honest fallback disclosure
    expect(find.textContaining('Translation in Telugu (తెలుగు) is unavailable'), findsOneWidget);
    expect(find.text('Verify tracking number on the official carrier site.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains scrollable on narrow screen with zero overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: AnalysisResultScreen(analysis: _scamAnalysis),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Scam Detected'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Analyze Another'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Analyze Another'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actions trigger callbacks and show save confirmation', (
    tester,
  ) async {
    var requestedAnotherAnalysis = false;
    var openedHistory = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisResultScreen(
          analysis: _scamAnalysis,
          onAnalyzeAnother: () => requestedAnotherAnalysis = true,
          onOpenHistory: () => openedHistory = true,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Analyze Another'));
    await tester.tap(find.text('Analyze Another'));
    expect(requestedAnotherAnalysis, isTrue);

    await tester.ensureVisible(find.text('Save to History'));
    await tester.tap(find.text('Save to History'));
    await tester.pumpAndSettle();

    expect(find.textContaining('is securely stored in your History'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    await tester.tap(find.text('View'));
    expect(openedHistory, isTrue);
    expect(tester.takeException(), isNull);
  });
}
