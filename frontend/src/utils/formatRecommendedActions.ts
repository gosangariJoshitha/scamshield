export function formatRecommendedActions(action: string): string[] {
  let actionText = action;
  try {
    const structured = JSON.parse(action) as { canonical?: unknown };
    if (Array.isArray(structured.canonical)) {
      actionText = structured.canonical
        .filter((item): item is string => typeof item === 'string')
        .join('\n');
    }
  } catch {
    // Existing records contain plain text rather than structured actions.
  }

  const normalized = actionText
    .replace(/\r\n?/g, '\n')
    .replace(/(?:resolution steps|recommended actions?|what to do)\s*:\s*/gi, '\n')
    .trim();

  const candidates = normalized
    .split(/\n+|\s+(?=\d+[.)]\s)|(?<=[.!?।])\s+/u)
    .flatMap((part) => part.split(/\s+(?=Do not\b|Don't\b|Never\b|Verify\b|Report\b|Contact\b|Open\b|Check\b|Use\b|Avoid\b)/i))
    .map((part) => part.replace(/^\s*\d+[.)]\s*/, '').trim())
    .filter((part) => part.length > 5);

  const uniqueActions = new Set<string>();
  return candidates.filter((candidate) => {
    const normalizedCandidate = candidate.toLocaleLowerCase();
    if (uniqueActions.has(normalizedCandidate)) {
      return false;
    }
    uniqueActions.add(normalizedCandidate);
    return true;
  });
}
