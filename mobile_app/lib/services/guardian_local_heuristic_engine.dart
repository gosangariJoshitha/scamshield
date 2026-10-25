import 'package:flutter/foundation.dart';

@immutable
class GuardianLocalHeuristicResult {
  const GuardianLocalHeuristicResult({
    required this.matchedRules,
    required this.matchedPhrases,
    required this.warningHeadline,
    required this.safeAction,
    required this.evaluatedAt,
    required this.engineVersion,
    required this.hasMatches,
  });

  final List<String> matchedRules;
  final List<String> matchedPhrases;
  final String warningHeadline;
  final String safeAction;
  final DateTime evaluatedAt;
  final String engineVersion;
  final bool hasMatches;

  static const String noMatchNotice =
      'No local rule matched. This does not establish that the conversation is safe.';
}

class GuardianLocalHeuristicEngine {
  static const String version = '1.0.0';

  // Rule IDs
  static const String ruleCredentialDemand = 'RULE_CREDENTIAL_DEMAND';
  static const String ruleRemoteAccessTool = 'RULE_REMOTE_ACCESS_TOOL';
  static const String ruleUrgentTransfer = 'RULE_URGENT_TRANSFER';
  static const String ruleGovtImpersonationArrest =
      'RULE_GOVT_IMPERSONATION_ARREST';

  // English Patterns (regex word boundaries)
  static final RegExp _enCredentialRegex = RegExp(
    r'\b(otp|one[- ]time password|atm pin|upi pin|netbanking password|passcode|cvv)\b',
    caseSensitive: false,
  );

  static final RegExp _enRemoteAccessRegex = RegExp(
    r'\b(anydesk|teamviewer|rustdesk|quicksupport|airdroid)\b',
    caseSensitive: false,
  );

  static final RegExp _enUrgentTransferRegex = RegExp(
    r'\b(transfer money immediately|send money now|pay fee to unblock|safe account|urgent transfer|pay penalty now|send money immediately)\b',
    caseSensitive: false,
  );

  static final RegExp _enGovtArrestRegex = RegExp(
    r'\b(digital arrest|cbi officer|narcotics bureau|customs parcel|police warrant|arrest warrant|illegal parcel)\b',
    caseSensitive: false,
  );

  // Hindi / Devanagari Patterns & Romanized Hindi
  static final RegExp _hiDevanagariCredentialRegex = RegExp(
    r'(?:^|\s)(ओटीपी|पिन|पासवर्ड|सीवीवी)(?=\s|$)',
  );

  static final RegExp _hiRomanCredentialRegex = RegExp(
    r'\b(otp batao|pin batao|password batao|otp dijiye|pin dijiye)\b',
    caseSensitive: false,
  );

  static final RegExp _hiDevanagariRemoteAccessRegex = RegExp(
    r'(?:^|\s)(एनीडेस्क|टीमव्यूअर|रस्टडेस्क|क्विकसपोर्ट)(?=\s|$)',
  );

  static final RegExp _hiRomanRemoteAccessRegex = RegExp(
    r'\b(anydesk download|teamviewer download)\b',
    caseSensitive: false,
  );

  static final RegExp _hiDevanagariUrgentTransferRegex = RegExp(
    r'(?:^|\s)(पैसे ट्रांसफर|पैसे भेजो|तुरंत पैसे|खाता ब्लॉक)(?=\s|$)',
  );

  static final RegExp _hiRomanUrgentTransferRegex = RegExp(
    r'\b(paise bhejo|turant paise transfer|paise bhejiye|khata block ho jayega)\b',
    caseSensitive: false,
  );

  static final RegExp _hiDevanagariGovtArrestRegex = RegExp(
    r'(?:^|\s)(डिजिटल अरेस्ट|गिरफ्तारी वारंट|पुलिस केस|सीबीआई)(?=\s|$)',
  );

  static final RegExp _hiRomanGovtArrestRegex = RegExp(
    r'\b(digital arrest|police case|customs parcel|cbi officer)\b',
    caseSensitive: false,
  );

  // Telugu Script & Romanized Telugu Patterns
  static final RegExp _teScriptCredentialRegex = RegExp(
    r'(?:^|\s)(ఓటీపీ|పిన్|పాస్‌వర్డ్|పాస్ వర్డ్)(?=\s|$)',
  );

  static final RegExp _teRomanCredentialRegex = RegExp(
    r'\b(otp cheppandi|pin cheppandi|password cheppandi|otp ivvandi)\b',
    caseSensitive: false,
  );

  static final RegExp _teScriptRemoteAccessRegex = RegExp(
    r'(?:^|\s)(ఎనీడెస్క్|టీమ్‌వ్యూయర్|రస్ట్‌డెస్క్)(?=\s|$)',
  );

  static final RegExp _teRomanRemoteAccessRegex = RegExp(
    r'\b(anydesk install|teamviewer install)\b',
    caseSensitive: false,
  );

  static final RegExp _teScriptUrgentTransferRegex = RegExp(
    r'(?:^|\s)(డబ్బులు పంపండి|వెంటనే డబ్బులు|ఖాతా బ్లాక్|డబ్బు బదిలీ)(?=\s|$)',
  );

  static final RegExp _teRomanUrgentTransferRegex = RegExp(
    r'\b(dabbu pampandi|dabbulu transfer|ventane dabbu|khata block)\b',
    caseSensitive: false,
  );

  static final RegExp _teScriptGovtArrestRegex = RegExp(
    r'(?:^|\s)(డిజిటల్ అరెస్ట్|అరెస్ట్ వారెంట్|పోలీస్ కేసు)(?=\s|$)',
  );

  static final RegExp _teRomanGovtArrestRegex = RegExp(
    r'\b(digital arrest|police case|arrest warrant)\b',
    caseSensitive: false,
  );

  String normalize(String text) {
    if (text.isEmpty) return '';
    // Preserve letters, digits, and Indian scripts (Devanagari \u0900-\u097F, Telugu \u0C00-\u0C7F)
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F\u0C00-\u0C7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  GuardianLocalHeuristicResult evaluate(String rawText) {
    final normalized = normalize(rawText);
    final now = DateTime.now();

    if (normalized.isEmpty) {
      return GuardianLocalHeuristicResult(
        matchedRules: const [],
        matchedPhrases: const [],
        warningHeadline: 'No local rule matched.',
        safeAction: GuardianLocalHeuristicResult.noMatchNotice,
        evaluatedAt: now,
        engineVersion: version,
        hasMatches: false,
      );
    }

    final matchedRules = <String>[];
    final matchedPhrases = <String>[];

    void recordMatches(String ruleId, List<RegExpMatch> matches) {
      if (matches.isNotEmpty) {
        if (!matchedRules.contains(ruleId)) {
          matchedRules.add(ruleId);
        }
        for (final m in matches) {
          final phrase = (m.groupCount >= 1 ? m.group(1) : m.group(0))?.trim();
          if (phrase != null &&
              phrase.isNotEmpty &&
              !matchedPhrases.contains(phrase)) {
            matchedPhrases.add(phrase);
          }
        }
      }
    }

    // Check Rule: Credential Demand (OTP, PIN, Password, CVV)
    recordMatches(ruleCredentialDemand, [
      ..._enCredentialRegex.allMatches(normalized),
      ..._hiDevanagariCredentialRegex.allMatches(normalized),
      ..._hiRomanCredentialRegex.allMatches(normalized),
      ..._teScriptCredentialRegex.allMatches(normalized),
      ..._teRomanCredentialRegex.allMatches(normalized),
    ]);

    // Check Rule: Remote Access Tool (AnyDesk, TeamViewer, RustDesk)
    recordMatches(ruleRemoteAccessTool, [
      ..._enRemoteAccessRegex.allMatches(normalized),
      ..._hiDevanagariRemoteAccessRegex.allMatches(normalized),
      ..._hiRomanRemoteAccessRegex.allMatches(normalized),
      ..._teScriptRemoteAccessRegex.allMatches(normalized),
      ..._teRomanRemoteAccessRegex.allMatches(normalized),
    ]);

    // Check Rule: Urgent Transfer / Safe Account Demand
    recordMatches(ruleUrgentTransfer, [
      ..._enUrgentTransferRegex.allMatches(normalized),
      ..._hiDevanagariUrgentTransferRegex.allMatches(normalized),
      ..._hiRomanUrgentTransferRegex.allMatches(normalized),
      ..._teScriptUrgentTransferRegex.allMatches(normalized),
      ..._teRomanUrgentTransferRegex.allMatches(normalized),
    ]);

    // Check Rule: Govt Impersonation / Digital Arrest
    recordMatches(ruleGovtImpersonationArrest, [
      ..._enGovtArrestRegex.allMatches(normalized),
      ..._hiDevanagariGovtArrestRegex.allMatches(normalized),
      ..._hiRomanGovtArrestRegex.allMatches(normalized),
      ..._teScriptGovtArrestRegex.allMatches(normalized),
      ..._teRomanGovtArrestRegex.allMatches(normalized),
    ]);

    if (matchedRules.isEmpty) {
      return GuardianLocalHeuristicResult(
        matchedRules: const [],
        matchedPhrases: const [],
        warningHeadline: 'No local rule matched.',
        safeAction: GuardianLocalHeuristicResult.noMatchNotice,
        evaluatedAt: now,
        engineVersion: version,
        hasMatches: false,
      );
    }

    // Determine prioritized headline and safe action
    String headline;
    String safeAction;

    if (matchedRules.contains(ruleGovtImpersonationArrest)) {
      headline = 'Urgent: Impersonation / Digital arrest intimidation pattern detected';
      safeAction =
          'Indian authorities never conduct "Digital Arrest" over phone or video. Disconnect immediately and report to 1930.';
    } else if (matchedRules.contains(ruleRemoteAccessTool)) {
      headline = 'Urgent: Screen-sharing application installation requested';
      safeAction =
          'Never install AnyDesk, TeamViewer, or remote access apps on instructions from unknown callers.';
    } else if (matchedRules.contains(ruleCredentialDemand)) {
      headline = 'High Risk: Confidential credential demand detected';
      safeAction =
          'Never share OTP, PIN, password, or CVV. Legitimate banks and government agencies never ask for credentials.';
    } else {
      headline = 'High Risk: Urgent payment or account freeze threat detected';
      safeAction =
          'Never transfer money to a "safe account" or unblock fee. Verify directly with your bank through official branches.';
    }

    return GuardianLocalHeuristicResult(
      matchedRules: List.unmodifiable(matchedRules),
      matchedPhrases: List.unmodifiable(matchedPhrases),
      warningHeadline: headline,
      safeAction: safeAction,
      evaluatedAt: now,
      engineVersion: version,
      hasMatches: true,
    );
  }
}
