import logging
import re
from collections.abc import Mapping
from difflib import SequenceMatcher
from typing import Any


logger = logging.getLogger(__name__)

SUPPORTED_LANGUAGES = ("en", "hi", "te")
DEFAULT_CANONICAL_ACTIONS = [
    "Do not open links or attachments until the sender is verified.",
    "Never share OTPs, passwords, or banking credentials.",
    "Verify requests through the organization's official app, website, or phone number.",
]


def detect_language(text: str, language_hint: str | None = None) -> str:
    if isinstance(language_hint, str) and language_hint in SUPPORTED_LANGUAGES:
        return language_hint
    devanagari_count = sum("\u0900" <= char <= "\u097f" for char in text)
    telugu_count = sum("\u0c00" <= char <= "\u0c7f" for char in text)
    if devanagari_count or telugu_count:
        return "hi" if devanagari_count >= telugu_count else "te"
    return "en"


def normalize_safe_actions(
    value: Any,
    default_language: str,
) -> dict[str, Any]:
    raw = value if isinstance(value, Mapping) else {}
    raw_canonical = raw.get("canonical", [])
    canonical_entries: list[tuple[str, int]] = []
    seen: list[str] = []
    use_fallback = False

    if isinstance(raw_canonical, list):
        for source_index, action in enumerate(raw_canonical):
            if not isinstance(action, str):
                continue
            cleaned = re.sub(r"^\s*(?:\d+[.)]\s*|[-*•]\s*)", "", action)
            cleaned = re.sub(r"\s+", " ", cleaned).strip()
            if not cleaned:
                continue
            normalized = cleaned.casefold()
            if any(
                SequenceMatcher(None, normalized, previous).ratio() >= 0.94
                for previous in seen
            ):
                continue
            canonical_entries.append((cleaned, source_index))
            seen.append(normalized)
            if len(canonical_entries) == 6:
                break

    if len(canonical_entries) < 3:
        logger.warning(
            "LLM returned fewer than three distinct safety actions; using the safe-action fallback."
        )
        canonical_entries = [
            (action, index)
            for index, action in enumerate(DEFAULT_CANONICAL_ACTIONS)
        ]
        use_fallback = True

    canonical = [action for action, _ in canonical_entries]
    raw_translations = raw.get("translations", {})
    raw_translations = (
        raw_translations
        if isinstance(raw_translations, Mapping) and not use_fallback
        else {}
    )
    translations: dict[str, list[str]] = {"en": canonical.copy()}
    for language in ("hi", "te"):
        language_values = raw_translations.get(language, [])
        normalized_values: list[str] = []
        for action_index, (action, source_index) in enumerate(canonical_entries):
            translated = (
                language_values[source_index]
                if isinstance(language_values, list)
                and source_index < len(language_values)
                and isinstance(language_values[source_index], str)
                else ""
            )
            translated = re.sub(r"\s+", " ", translated).strip()
            if not translated:
                logger.warning(
                    "Missing %s translation for recommended action %d; using its canonical English text.",
                    language,
                    action_index + 1,
                )
                translated = action
            normalized_values.append(translated)
        translations[language] = normalized_values

    selected_language = (
        default_language if default_language in SUPPORTED_LANGUAGES else "en"
    )
    return {
        "canonical": canonical,
        "translations": translations,
        "default_language": selected_language,
    }


def fallback_safe_actions(
    default_language: str,
    primary_action: str | None = None,
) -> dict[str, Any]:
    logger.warning(
        "Localized safety actions are unavailable; English fallback actions will be shown."
    )
    canonical = DEFAULT_CANONICAL_ACTIONS.copy()
    if primary_action and primary_action.strip():
        canonical[0] = primary_action.strip()
    return normalize_safe_actions({"canonical": canonical}, default_language)
