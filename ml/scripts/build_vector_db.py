import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = ROOT / "backend"
KNOWLEDGE_PATH = ROOT / "ml" / "data" / "raw" / "knowledge_base.json"
sys.path.insert(0, str(BACKEND_DIR))
sys.path.insert(0, str(ROOT))

from database import SessionLocal
from models import KnowledgeEntry
from app.services.embedding_service import embedding_service
from app.services.rag_service import rag_service
from ml.scripts.knowledge_base_source import (
    LANGUAGES,
    load_knowledge_records,
    localized_document,
)


MANAGED_SOURCE_TYPES = {
    "AUDITED_DATASET",
    "CANONICAL_KNOWLEDGE_BASE",
    "CURATED_KNOWLEDGE_BASE",
    "EXTERNAL_GUIDANCE",
}


def _entry_for_record(db, record):
    return db.query(KnowledgeEntry).filter(
        KnowledgeEntry.source_type == record["source_type"],
        KnowledgeEntry.source_reference == record["source_reference"],
    ).first()


def ingest_knowledge() -> tuple[int, int]:
    data, records = load_knowledge_records(KNOWLEDGE_PATH)
    db = SessionLocal()
    try:
        previous_entries = db.query(KnowledgeEntry).filter(
            KnowledgeEntry.source_type.in_(MANAGED_SOURCE_TYPES)
        ).all()
        previous_managed_ids = {entry.id for entry in previous_entries}
        records_by_source = {
            (record["source_type"], record["source_reference"]): record
            for record in records
        }

        entries_by_record = {}
        for record in records:
            entry = _entry_for_record(db, record)
            if entry is None:
                entry = KnowledgeEntry()
                db.add(entry)
            english = record["variants"]["en"]
            entry.title = record["title"]
            entry.pattern = record["pattern"]
            entry.category = record["category"]
            entry.description = english["overview"]
            entry.indicators = english["indicators"]
            entry.example = "\n".join(english["examples"])
            entry.safe_action = english["safe_action"]
            entry.risk_level = record["risk_level"]
            entry.source = record["source"]
            entry.source_type = record["source_type"]
            entry.source_reference = record["source_reference"]
            entry.status = "ACTIVE"
            entries_by_record[record["id"]] = entry

        db.flush()
        active_managed_ids = set()
        for entry in previous_entries:
            key = (entry.source_type, entry.source_reference)
            if key not in records_by_source:
                entry.status = "INACTIVE"
            else:
                active_managed_ids.add(entry.id)

        documents = []
        document_ids = []
        metadatas = []
        for record in records:
            entry = entries_by_record[record["id"]]
            active_managed_ids.add(entry.id)
            for language in LANGUAGES:
                variant = record["variants"][language]
                document_ids.append(f"knowledge_{entry.id}_{language}")
                documents.append(localized_document(record, language))
                metadatas.append({
                    "id": entry.id,
                    "title": record["title"],
                    "category": record["category"],
                    "pattern": variant["overview"],
                    "safe_action": variant["safe_action"],
                    "source": record["source"],
                    "source_type": record["source_type"],
                    "source_reference": record["source_reference"],
                    "language": language,
                    "label": record["label"],
                })

        preserved_entries = db.query(KnowledgeEntry).filter(
            KnowledgeEntry.status.in_(["ACTIVE", "APPROVED"]),
            KnowledgeEntry.source_type.notin_(MANAGED_SOURCE_TYPES),
        ).all()
        for entry in preserved_entries:
            rag_service.upsert_knowledge_entry(entry)

        embeddings = embedding_service.generate_embeddings(documents)
        if len(embeddings) != len(documents):
            raise ValueError(
                "Embedding service returned a different number of vectors than documents."
            )
        rag_service.collection.upsert(
            ids=document_ids,
            embeddings=embeddings,
            documents=documents,
            metadatas=metadatas,
        )

        current_vectors = rag_service.collection.get(include=["metadatas"])
        stale_ids = []
        for vector_id, metadata in zip(
            current_vectors["ids"],
            current_vectors.get("metadatas") or [],
        ):
            vector_type = (metadata or {}).get("source_type")
            vector_entry_id = (metadata or {}).get("id")
            if (
                vector_type in MANAGED_SOURCE_TYPES
                and vector_entry_id not in active_managed_ids
            ) or (
                vector_entry_id in previous_managed_ids
                and vector_entry_id not in active_managed_ids
            ):
                stale_ids.append(vector_id)
        if stale_ids:
            rag_service.collection.delete(ids=stale_ids)

        db.commit()
        print(
            f"Validated KB v{data.get('version')}: "
            f"{len(data['articles'])} total articles "
            f"({sum(record['source_type'] == 'CANONICAL_KNOWLEDGE_BASE' for record in records)} "
            "scam/genuine patterns and "
            f"{sum(record['source_type'] == 'EXTERNAL_GUIDANCE' for record in records)} "
            "external sources)."
        )
        print(
            f"Active SQL records: {len(records)}; "
            f"localized Chroma documents: {len(document_ids)}; "
            f"retired stale managed vectors: {len(stale_ids)}."
        )
        return len(records), len(document_ids)
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    ingest_knowledge()
