import csv
import json
import random
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = ROOT / "backend"
PROCESSED_DIR = (
    ROOT
    / "ml"
    / "data"
    / "processed"
    / "scamshield-dataset-8424-v10.1"
)
KNOWLEDGE_PATH = ROOT / "ml" / "data" / "raw" / "knowledge_base.json"
REPORT_PATH = ROOT / "ml" / "reports" / "rag_metrics.json"
QUERY_COUNT = 50
RANDOM_SEED = 42
sys.path.insert(0, str(BACKEND_DIR))
sys.path.insert(0, str(ROOT))

from database import SessionLocal
from models import KnowledgeEntry
from app.services.embedding_service import EMBEDDING_MODEL
from app.services.rag_service import RAG_MIN_SIMILARITY, RAG_TOP_K, rag_service
from ml.scripts.knowledge_base_source import load_knowledge_records


def _select_queries(test, known_categories):
    scam_test = [row for row in test if row["label"] == "scam"]
    eligible = [
        row for row in scam_test if row["scam_category"] in known_categories
    ]
    if len(eligible) < QUERY_COUNT:
        raise ValueError(
            f"Only {len(eligible)} held-out scam examples have an exact KB category; "
            f"{QUERY_COUNT} are required for evaluation."
        )

    grouped = {}
    for row in eligible:
        grouped.setdefault((row["scam_category"], row["language"]), []).append(row)
    for rows in grouped.values():
        rows.sort(key=lambda row: row["sample_id"])
    first_per_group = [rows[0] for rows in grouped.values()]
    if len(first_per_group) >= QUERY_COUNT:
        candidates = first_per_group
    else:
        candidates = [
            row
            for rows in grouped.values()
            for row in rows[:2]
        ]
    selected = random.Random(RANDOM_SEED).sample(candidates, QUERY_COUNT)
    selected.sort(
        key=lambda row: (
            row["scam_category"],
            row["language"],
            row["sample_id"],
        )
    )
    return selected, scam_test


def evaluate_rag():
    knowledge, _ = load_knowledge_records(KNOWLEDGE_PATH)
    scam_articles = [
        article for article in knowledge["articles"]
        if article.get("type") == "scam_pattern"
    ]
    known_categories = {article["category"] for article in scam_articles}
    with (PROCESSED_DIR / "test.csv").open(
        encoding="utf-8", newline=""
    ) as test_file:
        test = list(csv.DictReader(test_file))
    split_metadata = json.loads(
        (PROCESSED_DIR / "split_metadata.json").read_text(encoding="utf-8")
    )
    if len(test) != split_metadata["splits"]["test"]["row_count"]:
        raise ValueError("Test split size does not match split metadata.")

    queries, scam_test = _select_queries(test, known_categories)
    db = SessionLocal()
    try:
        indexed_entries = db.query(KnowledgeEntry).filter(
            KnowledgeEntry.source_type == "CANONICAL_KNOWLEDGE_BASE",
            KnowledgeEntry.status.in_(["ACTIVE", "APPROVED"]),
        ).all()
        ids_by_category = {}
        for entry in indexed_entries:
            ids_by_category.setdefault(entry.category, set()).add(entry.id)
    finally:
        db.close()

    hits = {1: 0, 3: 0, 5: 0}
    reciprocal_ranks = []
    covered_queries = 0
    top_similarities = []
    query_results = []
    for row in queries:
        expected_category = row["scam_category"]
        relevant_ids = ids_by_category.get(expected_category, set())
        if not relevant_ids:
            raise ValueError(
                f"Expected category {expected_category!r} has no active SQL knowledge entry."
            )
        result = rag_service.search(
            row["text"],
            top_k=RAG_TOP_K,
            language=row["language"],
        )
        evidence = result.get("retrieved_evidence", [])
        if evidence:
            covered_queries += 1
            top_similarities.append(float(evidence[0]["similarity_score"]))
        ranks = [
            rank
            for rank, item in enumerate(evidence, start=1)
            if item.get("knowledge_id") in relevant_ids
        ]
        first_rank = min(ranks) if ranks else None
        for k in hits:
            if first_rank is not None and first_rank <= k:
                hits[k] += 1
        reciprocal_ranks.append(1.0 / first_rank if first_rank else 0.0)
        query_results.append({
            "sample_id": row["sample_id"],
            "expected_category": expected_category,
            "language": row["language"],
            "input_channel": row["input_channel"],
            "first_relevant_rank": first_rank,
            "retrieved_patterns": [item.get("pattern") for item in evidence],
            "top_similarity": (
                float(evidence[0]["similarity_score"]) if evidence else None
            ),
            "evidence_status": result.get("evidence_status"),
            "retrieved_languages": [item.get("language") for item in evidence],
        })

    uncovered = [
        row for row in scam_test if row["scam_category"] not in known_categories
    ]
    denominator = len(queries)
    metrics = {
        "hit_at_1": hits[1] / denominator,
        "hit_at_3": hits[3] / denominator,
        "hit_at_5": hits[5] / denominator,
        "recall_at_1": hits[1] / denominator,
        "recall_at_3": hits[3] / denominator,
        "recall_at_5": hits[5] / denominator,
        "mean_reciprocal_rank": sum(reciprocal_ranks) / denominator,
        "evidence_coverage": covered_queries / denominator,
        "average_top_similarity": (
            sum(top_similarities) / len(top_similarities)
            if top_similarities
            else None
        ),
        "average_similarity_query_count": len(top_similarities),
        "insufficient_knowledge_rate": (
            len(uncovered) / len(scam_test) if len(scam_test) else None
        ),
        "insufficient_knowledge_basis": (
            "Share of held-out scam rows whose exact category is absent "
            "from active indexed scam knowledge entries."
        ),
        "uncovered_test_categories": sorted(
            {row["scam_category"] for row in uncovered}
        ),
        "query_results": query_results,
        "metadata": {
            "evaluation_queries": denominator,
            "query_source": "Held-out test split; not independent of KB source corpus.",
            "selection": (
                "Scam-labeled test records with an exact category-to-KB-article "
                "match; stratified by category and language with seed 42."
            ),
            "dataset_version": split_metadata["dataset_version"],
            "knowledge_source_articles": len(scam_articles),
            "external_guidance_documents": sum(
                article.get("type") == "external_guidance"
                for article in knowledge["articles"]
            ),
            "active_sql_pattern_entries": len(indexed_entries),
            "embedding_model": EMBEDDING_MODEL,
            "distance": rag_service.collection.metadata.get("hnsw:space"),
            "top_k": RAG_TOP_K,
            "minimum_similarity": RAG_MIN_SIMILARITY,
            "evaluation_timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "limitation": (
                "This is an exploratory retrieval benchmark on dataset-derived "
                "examples; it is not an independent human-labeled evaluation."
            ),
        },
    }
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(
        json.dumps(metrics, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"RAG evaluation completed: {denominator} queries; "
        f"hit@1={metrics['hit_at_1']:.3f}, "
        f"hit@3={metrics['hit_at_3']:.3f}, "
        f"hit@5={metrics['hit_at_5']:.3f}, "
        f"MRR={metrics['mean_reciprocal_rank']:.3f}, "
        f"evidence coverage={metrics['evidence_coverage']:.3f}."
    )
    print(
        f"Exact-category knowledge gaps in held-out scam rows: "
        f"{len(uncovered)}/{len(scam_test)}."
    )


if __name__ == "__main__":
    evaluate_rag()
