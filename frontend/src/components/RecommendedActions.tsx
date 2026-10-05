import { useState } from 'react';
import { formatRecommendedActions } from '../utils/formatRecommendedActions';
import type { SafeActions } from '../services/analysis';

const LANGUAGES = [
  { code: 'en', label: 'English' },
  { code: 'hi', label: 'हिंदी' },
  { code: 'te', label: 'తెలుగు' },
] as const;

type Language = typeof LANGUAGES[number]['code'];

function detectLanguage(text: string): Language {
  let devanagariCount = 0;
  let teluguCount = 0;
  for (const character of text) {
    const codePoint = character.codePointAt(0) ?? 0;
    if (codePoint >= 0x0900 && codePoint <= 0x097f) devanagariCount += 1;
    if (codePoint >= 0x0c00 && codePoint <= 0x0c7f) teluguCount += 1;
  }
  if (devanagariCount || teluguCount) {
    return devanagariCount >= teluguCount ? 'hi' : 'te';
  }
  return 'en';
}

interface RecommendedActionsProps {
  recommendedAction: string;
  safeActions?: SafeActions | null;
  analyzedText: string;
}

export default function RecommendedActions({
  recommendedAction,
  safeActions,
  analyzedText,
}: RecommendedActionsProps) {
  const canonical = safeActions?.canonical?.length
    ? safeActions.canonical
    : formatRecommendedActions(recommendedAction);
  const initialLanguage = safeActions?.default_language ?? detectLanguage(analyzedText);
  const [selectedLanguage, setSelectedLanguage] = useState<Language>(initialLanguage);

  const translatedActions = safeActions?.translations?.[selectedLanguage];
  const actions = translatedActions?.length === canonical.length
    && translatedActions.every((action) => typeof action === 'string' && action.trim())
    ? translatedActions
    : canonical;
  const selectedLabel = LANGUAGES.find(({ code }) => code === selectedLanguage)?.label;

  return (
    <div>
      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm font-medium text-text-secondary">Show actions in</p>
        <div className="flex flex-wrap gap-2" role="group" aria-label="Recommended action language">
          {LANGUAGES.map(({ code, label }) => (
            <button
              key={code}
              type="button"
              aria-pressed={selectedLanguage === code}
              onClick={() => setSelectedLanguage(code)}
              className={`min-h-10 rounded-lg border px-3 py-2 text-sm font-semibold transition ${
                selectedLanguage === code
                  ? 'border-primary bg-primary text-white'
                  : 'border-border-light bg-background text-text-secondary hover:border-primary hover:text-primary'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>
      <ol
        lang={selectedLanguage}
        aria-label={`Recommended actions in ${selectedLabel}`}
        className="ml-5 list-decimal space-y-3 pl-2 text-sm leading-relaxed text-text-secondary sm:text-base"
      >
        {actions.map((action, index) => (
          <li key={`${index}-${canonical[index]}`} className="break-words pl-1 [overflow-wrap:anywhere]">
            {action}
          </li>
        ))}
      </ol>
    </div>
  );
}
