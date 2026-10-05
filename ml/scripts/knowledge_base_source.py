import json
from pathlib import Path
from typing import Any


LANGUAGES = ("en", "hi", "te")


def load_knowledge_records(path: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    if not path.is_file():
        raise FileNotFoundError(f"Canonical knowledge base not found: {path}")

    data = json.loads(path.read_text(encoding="utf-8"))
    articles = data.get("articles")
    if not isinstance(articles, list):
        raise ValueError("Knowledge base must contain an articles list.")

    records: list[dict[str, Any]] = []
    identifiers: set[str] = set()

    def add_record(
        item: dict[str, Any],
        *,
        external: bool,
    ) -> None:
        identifier_key = "external_article_id" if external else "article_id"
        identifier = item.get(identifier_key)
        if not isinstance(identifier, str) or not identifier.strip():
            raise ValueError(f"Knowledge record has no {identifier_key}.")
        if identifier in identifiers:
            raise ValueError(f"Duplicate knowledge record ID: {identifier}")
        identifiers.add(identifier)

        variants = item.get("language_variants")
        if not isinstance(variants, dict):
            raise ValueError(f"{identifier} has no language variants.")
        normalized_variants = {}
        for language in LANGUAGES:
            variant = variants.get(language)
            if not isinstance(variant, dict):
                raise ValueError(f"{identifier} has no {language} language variant.")
            required = ("overview", "indicators", "safe_action")
            if any(not variant.get(field) for field in required):
                raise ValueError(
                    f"{identifier} has incomplete {language} guidance fields."
                )
            if not isinstance(variant["indicators"], list) or not all(
                isinstance(value, str) and value.strip()
                for value in variant["indicators"]
            ):
                raise ValueError(f"{identifier} has invalid {language} indicators.")
            for field in ("overview", "safe_action"):
                if not isinstance(variant[field], str) or not variant[field].strip():
                    raise ValueError(f"{identifier} has invalid {language} {field}.")
            steps = variant.get("resolution_steps", [])
            examples = variant.get("examples", [])
            if not isinstance(steps, list) or not all(
                isinstance(value, str) and value.strip() for value in steps
            ):
                raise ValueError(f"{identifier} has invalid {language} resolution steps.")
            if not isinstance(examples, list):
                raise ValueError(f"{identifier} has invalid {language} examples.")
            normalized_examples = []
            for example in examples:
                if isinstance(example, str) and example.strip():
                    normalized_examples.append(example.strip())
                elif (
                    isinstance(example, dict)
                    and isinstance(example.get("text"), str)
                    and example["text"].strip()
                    and example.get("language", language) == language
                ):
                    normalized_examples.append(example["text"].strip())
                else:
                    raise ValueError(
                        f"{identifier} has invalid {language} example data."
                    )
            normalized_variants[language] = {
                "overview": variant["overview"].strip(),
                "indicators": [value.strip() for value in variant["indicators"]],
                "safe_action": variant["safe_action"].strip(),
                "resolution_steps": [value.strip() for value in steps],
                "examples": normalized_examples,
            }

        if external:
            source_type = "EXTERNAL_GUIDANCE"
            article_type = item.get("type")
            if article_type != "external_guidance":
                raise ValueError(f"{identifier} is not external guidance.")
            source = f"{item.get('source_name', '')} {item.get('source_url', '')}"
            source_reference = identifier
            pattern = item.get("topic")
            category = item.get("topic")
            label = "supporting"
            risk_level = "INFO"
        else:
            source_type = "CANONICAL_KNOWLEDGE_BASE"
            article_type = item.get("type")
            if article_type not in {"scam_pattern", "genuine_pattern"}:
                raise ValueError(f"{identifier} has unsupported type {article_type!r}.")
            expected_label = "scam" if article_type == "scam_pattern" else "genuine"
            if item.get("label") != expected_label:
                raise ValueError(f"{identifier} has a label/type mismatch.")
            source = "ScamShield V10.1 Knowledge Base"
            source_reference = identifier
            pattern = item.get("pattern")
            category = item.get("category")
            label = expected_label
            severity = item.get("severity")
            risk_level = str(
                severity[0] if isinstance(severity, list) and severity else severity
            ).upper()
            if not isinstance(pattern, str) or not pattern.strip():
                raise ValueError(f"{identifier} has no pattern.")
            if not isinstance(category, str) or not category.strip():
                raise ValueError(f"{identifier} has no category.")

        title = item.get("title")
        if not isinstance(title, str) or not title.strip():
            raise ValueError(f"{identifier} has no title.")
        records.append({
            "id": identifier,
            "title": title.strip(),
            "pattern": str(pattern or "").strip(),
            "category": str(category or "").strip(),
            "label": label,
            "risk_level": risk_level,
            "source": str(source or "").strip(),
            "source_reference": str(source_reference or "").strip(),
            "source_type": source_type,
            "variants": normalized_variants,
        })

    for article in articles:
        if not isinstance(article, dict):
            raise ValueError("Knowledge base article entries must be objects.")
        article_type = article.get("type")
        if article_type == "external_guidance":
            add_record(article, external=True)
        elif article_type in {"scam_pattern", "genuine_pattern"}:
            add_record(article, external=False)
        else:
            raise ValueError(
                f"Unsupported knowledge article type: {article_type!r}"
            )

    declared = data.get("article_counts", {})
    pattern_count = sum(
        record["source_type"] == "CANONICAL_KNOWLEDGE_BASE"
        for record in records
    )
    external_count = sum(
        record["source_type"] == "EXTERNAL_GUIDANCE"
        for record in records
    )
    expected_counts = {
        "scam_patterns": sum(record["label"] == "scam" for record in records),
        "genuine_patterns": sum(record["label"] == "genuine" for record in records),
        "total_articles": len(articles),
        "external_guidance_articles": external_count,
        "total_retrieval_documents": len(records),
    }
    if pattern_count + external_count != len(articles):
        raise ValueError("Knowledge-base articles were not classified exactly once.")
    for name, expected in expected_counts.items():
        if name in declared and declared[name] != expected:
            raise ValueError(
                f"Knowledge-base count {name} is {declared[name]}, expected {expected}."
            )
    return data, records


def localized_document(record: dict[str, Any], language: str) -> str:
    variant = record["variants"][language]
    lines = [
        f"Title: {record['title']}",
        f"Category: {record['category']}",
        f"Pattern: {record['pattern']}",
        f"Description: {variant['overview']}",
        f"Indicators: {', '.join(variant['indicators'])}",
        f"Safe action: {variant['safe_action']}",
    ]
    if variant["resolution_steps"]:
        lines.append(f"Resolution steps: {'; '.join(variant['resolution_steps'])}")
    if variant["examples"]:
        lines.append(f"Examples: {'; '.join(variant['examples'])}")
    return "\n".join(lines)
