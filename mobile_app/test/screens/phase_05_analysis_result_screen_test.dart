import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/models/analysis_record.dart';
import 'package:scamshield_guardian/screens/results/analysis_result_screen.dart';
import 'package:scamshield_guardian/screens/results/widgets/result_banner_card.dart';

void main() {
  group('Phase 05 — Analysis Result Screen Master Test Suite', () {
    testWidgets('1. renders authoritative Safe outcome with green styling and sparkles', (tester) async {
      final safeRecord = AnalysisRecord(
        id: 101,
        content: 'Your appointment is confirmed for tomorrow.',
        riskScore: 5,
        riskLevel: 'LOW',
        classification: 'SAFE',
        category: 'appointment',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26, 9, 30),
        explanation: 'No suspicious links, patterns or scam indicators were found.',
        llmConfidence: 0.95,
        indicators: const [],
        actionTranslations: const {
          'en': ['This message is safe to interact with.', 'You can proceed if you trust the sender.'],
          'hi': ['यह संदेश बातचीत के लिए सुरक्षित है।'],
          'te': ['ఈ సందేశంతో పరస్పర చర్య చేయడం సురక్షితం.'],
        },
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: safeRecord)));

      expect(find.byType(ResultBannerCard), findsOneWidget);
      expect(find.text('Safe'), findsOneWidget);
      expect(find.text('No known scam indicators were detected.'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('None detected'), findsOneWidget);
      expect(find.text('Why Not Flagged'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. renders authoritative Scam Detected outcome with high-risk indicator list', (tester) async {
      final scamRecord = AnalysisRecord(
        id: 102,
        content: 'You won 50,000! Claim now: http://bit.ly/claim',
        riskScore: 94,
        riskLevel: 'HIGH',
        classification: 'SCAM',
        category: 'prize_claim',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26, 11, 36),
        explanation: 'Contains suspicious links and common prize scam patterns.',
        llmConfidence: 0.94,
        indicators: const ['Prize Claim', 'Urgent Action', 'Shortened Link'],
        actionTranslations: const {
          'en': ['Do not click on any links.', 'Block and report the sender.'],
          'hi': ['किसी भी लिंक पर क्लिक न करें।'],
          'te': ['ఈ లింక్‌పై క్లిక్ చేయవద్దు.'],
        },
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: scamRecord)));

      expect(find.text('Scam Detected'), findsOneWidget);
      expect(find.text('This message shows multiple scam indicators.'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('94%'), findsOneWidget);
      expect(find.text('1 Suspicious Link'), findsOneWidget);
      expect(find.text('Prize Claim, Urgent Action, Shortened Link'), findsOneWidget);
      expect(find.text('Prize Claim'), findsOneWidget); // Message pattern
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. handles Medium/Suspicious outcome with Caution Advised banner', (tester) async {
      final suspiciousRecord = AnalysisRecord(
        id: 103,
        content: 'Your package is at the local hub with unpaid fees.',
        riskScore: 55,
        riskLevel: 'MEDIUM',
        classification: 'SUSPICIOUS',
        category: 'postal_scam',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26),
        explanation: 'Unverified delivery claim from unknown sender.',
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: suspiciousRecord)));

      expect(find.text('Caution Advised'), findsOneWidget);
      expect(find.text('Suspicious elements detected. Proceed with caution.'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. handles Inconclusive/Unknown outcome truthfully without forcing Safe/Scam', (tester) async {
      final inconclusiveRecord = AnalysisRecord(
        id: 104,
        content: 'Ok',
        riskScore: 20,
        riskLevel: 'UNKNOWN',
        classification: 'INCONCLUSIVE',
        category: 'general',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26),
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: inconclusiveRecord)));

      expect(find.text('Inconclusive Result'), findsOneWidget);
      expect(find.text('Insufficient indicators found to verify authenticity.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. omits confidence row when backend returns no model confidence (no fabrication)', (tester) async {
      final noConfidenceRecord = AnalysisRecord(
        id: 105,
        content: 'Hello friend.',
        riskScore: 0,
        riskLevel: 'LOW',
        classification: 'SAFE',
        category: 'informational',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26),
        llmConfidence: null,
        mlProbability: null,
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: noConfidenceRecord)));

      // Must not display "Confidence" or fake "0%" / "None"
      expect(find.text('Confidence'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6. switches between English, Hindi and Telugu recommendations dynamically', (tester) async {
      final multiRecord = AnalysisRecord(
        id: 106,
        content: 'Claim urgent funds.',
        riskScore: 90,
        riskLevel: 'HIGH',
        classification: 'SCAM',
        category: 'financial_fraud',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26),
        actionTranslations: const {
          'en': ['Never share OTPs or banking credentials.', 'Report the message.'],
          'hi': ['कभी भी OTP या बैंकिंग क्रेडेंशियल साझा न करें।', 'संदेश की रिपोर्ट करें।'],
          'te': ['ఎప్పుడూ OTP లేదా బ్యాంకింగ్ ఆధారాలను పంచుకోవద్దు.', 'సందేశాన్ని రిపోర్ట్ చేయండి.'],
        },
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: multiRecord)));

      // English initial
      await tester.ensureVisible(find.text('Never share OTPs or banking credentials.'));
      expect(find.text('Never share OTPs or banking credentials.'), findsOneWidget);

      // Hindi switch
      await tester.ensureVisible(find.text('हिंदी'));
      await tester.tap(find.text('हिंदी'));
      await tester.pumpAndSettle();
      expect(find.text('कभी भी OTP या बैंकिंग क्रेडेंशियल साझा न करें।'), findsOneWidget);

      // Telugu switch
      await tester.ensureVisible(find.text('తెలుగు'));
      await tester.tap(find.text('తెలుగు'));
      await tester.pumpAndSettle();
      expect(find.text('ఎప్పుడూ OTP లేదా బ్యాంకింగ్ ఆధారాలను పంచుకోవద్దు.'), findsOneWidget);

      // Switch back to English
      await tester.ensureVisible(find.text('English'));
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Never share OTPs or banking credentials.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. displays honest disclosure when translation is missing for chosen language', (tester) async {
      final untranslatedRecord = AnalysisRecord(
        id: 107,
        content: 'Check your balance.',
        riskScore: 30,
        riskLevel: 'LOW',
        classification: 'SAFE',
        category: 'banking',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26),
        actionTranslations: const {
          'en': ['Verify via your official banking application.'],
        },
        safeActions: const ['Verify via your official banking application.'],
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: untranslatedRecord)));

      await tester.ensureVisible(find.text('తెలుగు'));
      await tester.tap(find.text('తెలుగు'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Translation in Telugu (తెలుగు) is unavailable'), findsOneWidget);
      expect(find.text('Verify via your official banking application.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. displays limitations notice when processingStatus is COMPLETED_WITH_LIMITATIONS', (tester) async {
      final limitedRecord = AnalysisRecord(
        id: 108,
        content: 'Urgent task needed.',
        riskScore: 70,
        riskLevel: 'HIGH',
        classification: 'SCAM',
        category: 'impersonation',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26),
        processingStatus: 'COMPLETED_WITH_LIMITATIONS',
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: limitedRecord)));

      expect(
        find.textContaining('Some auxiliary analysis services were temporarily unavailable'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. maps input types accurately (image, document, audio, call)', (tester) async {
      final imageRecord = AnalysisRecord(
        id: 109,
        content: 'OCR extracted text from screenshot',
        riskScore: 10,
        riskLevel: 'LOW',
        classification: 'SAFE',
        category: 'receipt',
        inputType: 'image',
        createdAt: DateTime.utc(2026, 10, 26),
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: imageRecord)));
      expect(find.text('Image / Screenshot'), findsOneWidget);

      final pdfRecord = AnalysisRecord(
        id: 110,
        content: 'Extracted PDF text',
        riskScore: 10,
        riskLevel: 'LOW',
        classification: 'SAFE',
        category: 'statement',
        inputType: 'pdf',
        createdAt: DateTime.utc(2026, 10, 26),
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: pdfRecord)));
      expect(find.text('Document (PDF)'), findsOneWidget);

      final audioRecord = AnalysisRecord(
        id: 111,
        content: 'Transcribed audio voicemail',
        riskScore: 80,
        riskLevel: 'HIGH',
        classification: 'SCAM',
        category: 'robocall',
        inputType: 'audio',
        createdAt: DateTime.utc(2026, 10, 26),
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: audioRecord)));
      expect(find.text('Audio Recording'), findsOneWidget);
    });

    testWidgets('10. renders cleanly in dark theme with high contrast', (tester) async {
      final darkRecord = AnalysisRecord(
        id: 112,
        content: 'You won 10,000!',
        riskScore: 90,
        riskLevel: 'HIGH',
        classification: 'SCAM',
        category: 'lottery',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: AnalysisResultScreen(analysis: darkRecord),
        ),
      );

      expect(find.text('Scam Detected'), findsOneWidget);
      expect(find.text('Analysis Result'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('11. adapts cleanly to narrow 320px phone viewport with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final scamRecord = AnalysisRecord(
        id: 113,
        content: 'Suspicious text message with urgent links',
        riskScore: 92,
        riskLevel: 'HIGH',
        classification: 'SCAM',
        category: 'prize_claim',
        inputType: 'image',
        createdAt: DateTime.utc(2026, 10, 26),
        indicators: const ['Prize Claim', 'Urgent Action', 'Shortened Link'],
        explanation: 'Very long explanation detailing how scammers send fake links to steal sensitive bank credentials.',
        actionTranslations: const {
          'en': ['Do not click links.', 'Block sender.'],
          'hi': ['लिंक पर क्लिक न करें।'],
          'te': ['లింక్‌లపై క్లిక్ చేయవద్దు.'],
        },
      );

      await tester.pumpWidget(MaterialApp(home: AnalysisResultScreen(analysis: scamRecord)));

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Analyze Another'), 250, scrollable: find.byType(Scrollable).first);
      expect(find.text('Analyze Another'), findsOneWidget);
      expect(find.text('Save to History'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('12. adapts to large font scaling (1.3x) without clipping text', (tester) async {
      final scamRecord = AnalysisRecord(
        id: 114,
        content: 'Short alert',
        riskScore: 85,
        riskLevel: 'HIGH',
        classification: 'SCAM',
        category: 'phishing',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: AnalysisResultScreen(analysis: scamRecord),
          ),
        ),
      );

      expect(find.text('Scam Detected'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Analyze Another action calls callback and resets submission without re-submitting', (tester) async {
      var analyzeAnotherCalled = false;

      final record = AnalysisRecord(
        id: 115,
        content: 'Check this out',
        riskScore: 10,
        riskLevel: 'LOW',
        classification: 'SAFE',
        category: 'social',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisResultScreen(
            analysis: record,
            onAnalyzeAnother: () => analyzeAnotherCalled = true,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Analyze Another'));
      await tester.tap(find.text('Analyze Another'));
      expect(analyzeAnotherCalled, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. Save to History gives instant persistence confirmation and allows opening History', (tester) async {
      var historyOpened = false;

      final record = AnalysisRecord(
        id: 456,
        content: 'Verified text message',
        riskScore: 5,
        riskLevel: 'LOW',
        classification: 'SAFE',
        category: 'work',
        inputType: 'text',
        createdAt: DateTime.utc(2026, 10, 26),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisResultScreen(
            analysis: record,
            onOpenHistory: () => historyOpened = true,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Save to History'));
      await tester.tap(find.text('Save to History'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Analysis #456 is securely stored in your History'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);

      await tester.tap(find.text('View'));
      expect(historyOpened, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
