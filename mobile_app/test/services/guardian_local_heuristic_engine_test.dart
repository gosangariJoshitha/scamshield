import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/services/guardian_local_heuristic_engine.dart';

void main() {
  group('GuardianLocalHeuristicEngine Tests', () {
    late GuardianLocalHeuristicEngine engine;

    setUp(() {
      engine = GuardianLocalHeuristicEngine();
    });

    test('version is 1.0.0', () {
      expect(GuardianLocalHeuristicEngine.version, '1.0.0');
    });

    group('English phrase detection', () {
      test('detects confidential credential demands (OTP, PIN, CVV, Password)', () {
        final result1 = engine.evaluate('Please share your OTP to confirm transaction.');
        expect(result1.hasMatches, isTrue);
        expect(result1.matchedRules, contains(GuardianLocalHeuristicEngine.ruleCredentialDemand));
        expect(result1.matchedPhrases, contains('otp'));
        expect(result1.safeAction, contains('Never share OTP, PIN, password'));

        final result2 = engine.evaluate('Tell me your ATM PIN and CVV immediately.');
        expect(result2.hasMatches, isTrue);
        expect(result2.matchedRules, contains(GuardianLocalHeuristicEngine.ruleCredentialDemand));
        expect(result2.matchedPhrases, contains('atm pin'));
        expect(result2.matchedPhrases, contains('cvv'));

        final result3 = engine.evaluate('Send me the one-time password on your mobile.');
        expect(result3.hasMatches, isTrue);
        expect(result3.matchedRules, contains(GuardianLocalHeuristicEngine.ruleCredentialDemand));
      });

      test('detects remote access screen-sharing tools', () {
        final result1 = engine.evaluate('Install AnyDesk application from Play Store now.');
        expect(result1.hasMatches, isTrue);
        expect(result1.matchedRules, contains(GuardianLocalHeuristicEngine.ruleRemoteAccessTool));
        expect(result1.matchedPhrases, contains('anydesk'));
        expect(result1.safeAction, contains('Never install AnyDesk'));

        final result2 = engine.evaluate('Open TeamViewer or QuickSupport for customer verification.');
        expect(result2.hasMatches, isTrue);
        expect(result2.matchedRules, contains(GuardianLocalHeuristicEngine.ruleRemoteAccessTool));
        expect(result2.matchedPhrases, contains('teamviewer'));
        expect(result2.matchedPhrases, contains('quicksupport'));
      });

      test('detects urgent fund transfers and safe account demands', () {
        final result1 = engine.evaluate('You must transfer money immediately to prevent account suspension.');
        expect(result1.hasMatches, isTrue);
        expect(result1.matchedRules, contains(GuardianLocalHeuristicEngine.ruleUrgentTransfer));
        expect(result1.matchedPhrases, contains('transfer money immediately'));

        final result2 = engine.evaluate('Deposit fee to safe account or pay penalty now.');
        expect(result2.hasMatches, isTrue);
        expect(result2.matchedRules, contains(GuardianLocalHeuristicEngine.ruleUrgentTransfer));
      });

      test('detects digital arrest and government agency intimidation', () {
        final result1 = engine.evaluate('This is digital arrest by CBI officer regarding illegal parcel.');
        expect(result1.hasMatches, isTrue);
        expect(result1.matchedRules, contains(GuardianLocalHeuristicEngine.ruleGovtImpersonationArrest));
        expect(result1.matchedPhrases, contains('digital arrest'));
        expect(result1.matchedPhrases, contains('cbi officer'));
        expect(result1.safeAction, contains('Digital Arrest'));

        final result2 = engine.evaluate('Police warrant issued by narcotics bureau for your customs parcel.');
        expect(result2.hasMatches, isTrue);
        expect(result2.matchedRules, contains(GuardianLocalHeuristicEngine.ruleGovtImpersonationArrest));
        expect(result2.matchedPhrases, contains('police warrant'));
        expect(result2.matchedPhrases, contains('narcotics bureau'));
      });
    });

    group('Hindi language coverage (Devanagari & Romanized)', () {
      test('detects OTP demand in Devanagari script', () {
        final result = engine.evaluate('तुरंत अपना ओटीपी और पिन बताइए।');
        expect(result.hasMatches, isTrue);
        expect(result.matchedRules, contains(GuardianLocalHeuristicEngine.ruleCredentialDemand));
        expect(result.matchedPhrases, contains('ओटीपी'));
      });

      test('detects remote access in Devanagari script', () {
        final result = engine.evaluate('अपने मोबाइल में एनीडेस्क ऐप डाउनलोड करें।');
        expect(result.hasMatches, isTrue);
        expect(result.matchedRules, contains(GuardianLocalHeuristicEngine.ruleRemoteAccessTool));
        expect(result.matchedPhrases, contains('एनीडेस्क'));
      });

      test('detects digital arrest and police in Devanagari script', () {
        final result = engine.evaluate('आपके खिलाफ डिजिटल अरेस्ट और पुलिस केस दर्ज हुआ है।');
        expect(result.hasMatches, isTrue);
        expect(result.matchedRules, contains(GuardianLocalHeuristicEngine.ruleGovtImpersonationArrest));
        expect(result.matchedPhrases, contains('डिजिटल अरेस्ट'));
      });

      test('detects Romanized Hindi phrases', () {
        final result1 = engine.evaluate('Sir jaldi apna otp batao nahi toh block ho jayega.');
        expect(result1.hasMatches, isTrue);
        expect(result1.matchedRules, contains(GuardianLocalHeuristicEngine.ruleCredentialDemand));

        final result2 = engine.evaluate('Turant safe account me paise bhejo.');
        expect(result2.hasMatches, isTrue);
        expect(result2.matchedRules, contains(GuardianLocalHeuristicEngine.ruleUrgentTransfer));
      });
    });

    group('Telugu language coverage (Telugu script & Romanized)', () {
      test('detects OTP demand in Telugu script', () {
        final result = engine.evaluate('దయచేసి మీ ఫోన్‌కు వచ్చిన ఓటీపీ చెప్పండి.');
        expect(result.hasMatches, isTrue);
        expect(result.matchedRules, contains(GuardianLocalHeuristicEngine.ruleCredentialDemand));
        expect(result.matchedPhrases, contains('ఓటీపీ'));
      });

      test('detects digital arrest in Telugu script', () {
        final result = engine.evaluate('మీపై డిజిటల్ అరెస్ట్ మరియు అరెస్ట్ వారెంట్ జారీ చేయబడింది.');
        expect(result.hasMatches, isTrue);
        expect(result.matchedRules, contains(GuardianLocalHeuristicEngine.ruleGovtImpersonationArrest));
        expect(result.matchedPhrases, contains('డిజిటల్ అరెస్ట్'));
      });

      test('detects Romanized Telugu phrases', () {
        final result1 = engine.evaluate('Ventane mee otp cheppandi bank manager matladutunnanu.');
        expect(result1.hasMatches, isTrue);
        expect(result1.matchedRules, contains(GuardianLocalHeuristicEngine.ruleCredentialDemand));

        final result2 = engine.evaluate('Khata block kakunda undalante dabbu pampandi.');
        expect(result2.hasMatches, isTrue);
        expect(result2.matchedRules, contains(GuardianLocalHeuristicEngine.ruleUrgentTransfer));
      });
    });

    group('False positive prevention and benign phrases', () {
      test('does not trigger on substrings like pin inside opinion, spinning, or shopping', () {
        final result1 = engine.evaluate('In my opinion, shopping online is very convenient.');
        expect(result1.hasMatches, isFalse);
        expect(result1.matchedRules, isEmpty);

        final result2 = engine.evaluate('The bicycle wheels were spinning rapidly.');
        expect(result2.hasMatches, isFalse);

        final result3 = engine.evaluate('I pinned the shopping list on the refrigerator board.');
        expect(result3.hasMatches, isFalse);
      });

      test('does not trigger on benign team, support, or desk discussions', () {
        final result1 = engine.evaluate('Our project team meeting is scheduled for tomorrow morning.');
        expect(result1.hasMatches, isFalse);

        final result2 = engine.evaluate('I left my laptop on the office desk.');
        expect(result2.hasMatches, isFalse);

        final result3 = engine.evaluate('Thank you for calling customer support, have a nice day.');
        expect(result3.hasMatches, isFalse);
      });

      test('does not trigger on benign family and parcel chats', () {
        final result = engine.evaluate('A birthday gift parcel arrived from my grandmother.');
        expect(result.hasMatches, isFalse);
      });
    });

    group('Truthful no-match behavior', () {
      test('returns honest no-match notice when text has no suspicious patterns', () {
        final result = engine.evaluate('Hello, how are you doing today?');
        expect(result.hasMatches, isFalse);
        expect(result.matchedRules, isEmpty);
        expect(result.matchedPhrases, isEmpty);
        expect(
          result.safeAction,
          GuardianLocalHeuristicResult.noMatchNotice,
        );
        expect(
          result.safeAction,
          'No local rule matched. This does not establish that the conversation is safe.',
        );
      });

      test('returns honest no-match notice on empty or whitespace input', () {
        final result = engine.evaluate('   ');
        expect(result.hasMatches, isFalse);
        expect(result.matchedRules, isEmpty);
        expect(
          result.safeAction,
          GuardianLocalHeuristicResult.noMatchNotice,
        );
      });
    });
  });
}
