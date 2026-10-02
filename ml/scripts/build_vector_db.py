import os
import json
import sys

# Add backend directory to sys.path so we can import from app
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../backend'))
sys.path.append(backend_dir)

from database import SessionLocal
from models import KnowledgeEntry
from app.services.rag_service import rag_service

def ingest_knowledge():
    db = SessionLocal()
    json_path = os.path.join(backend_dir, 'data', 'knowledgebase_100_articles.json')
    if not os.path.exists(json_path):
        db.close()
        raise FileNotFoundError(f"Knowledge base JSON not found: {json_path}")

    print(f"Synchronizing curated articles from {json_path}")
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    synced_count = 0
    for article in data.get("articles", []):
        if article.get("type") != "scam_pattern":
            continue

        article_id = article["article_id"]
        entry = db.query(KnowledgeEntry).filter(
            KnowledgeEntry.source_type == "CURATED_KNOWLEDGE_BASE",
            KnowledgeEntry.source_reference == article_id,
        ).first()
        if not entry:
            entry = db.query(KnowledgeEntry).filter(
                KnowledgeEntry.title == article.get("title", ""),
                KnowledgeEntry.source == "ScamShield Curated Database",
                KnowledgeEntry.source_reference.is_(None),
            ).first()
        if not entry:
            entry = KnowledgeEntry(status="ACTIVE")
            db.add(entry)

        examples = article.get("representative_examples", [])
        severity = article.get("severity", ["HIGH"])
        recommended_actions = article.get("recommended_action", [])
        localized_examples = [
            f"[{example.get('language', 'und')}] {example['text'].strip()}"
            for example in examples
            if isinstance(example.get("text"), str) and example["text"].strip()
        ]
        if not localized_examples:
            raise ValueError(f"Curated article {article_id} has no usable representative examples")
        entry.title = article.get("title", "")
        entry.pattern = article.get("pattern", "")
        entry.category = article.get("pattern", "")
        entry.description = article.get("overview", "")
        entry.indicators = article.get("common_indicators", [])
        entry.example = "\n".join(localized_examples)
        entry.safe_action = " ".join(recommended_actions)
        entry.risk_level = str(severity[0] if isinstance(severity, list) else severity).upper()
        entry.source = article.get("source_reference") or "ScamShield curated educational taxonomy"
        entry.source_type = "CURATED_KNOWLEDGE_BASE"
        entry.source_reference = article_id
        synced_count += 1

    db.commit()
    print(f"Synchronized {synced_count} curated articles to PostgreSQL.")
    
    # 2. Rebuild Vector DB
    entries = db.query(KnowledgeEntry).filter(
        KnowledgeEntry.status.in_(["ACTIVE", "APPROVED"])
    ).all()
    print(f"Found {len(entries)} active entries to embed.")
    
    ids = []
    documents = []
    metadatas = []
    
    for entry in entries:
        # Construct meaningful semantic representation
        text = f"Title: {entry.title}\nCategory: {entry.category}\nPattern: {entry.pattern}\nDescription: {entry.description}\nIndicators: {', '.join(entry.indicators) if entry.indicators else ''}\nExample: {entry.example}\nSafe Action: {entry.safe_action}"
        
        ids.append(f"knowledge_{entry.id}")
        documents.append(text)
        metadatas.append({
            "id": entry.id,
            "title": entry.title or "",
            "category": entry.category or "",
            "pattern": entry.pattern or "",
            "safe_action": entry.safe_action or "",
            "source": entry.source or ""
        })
    
    if documents:
        from app.services.embedding_service import embedding_service
        
        print("Generating embeddings...")
        embeddings = embedding_service.generate_embeddings(documents)
        
        print("Upserting into ChromaDB...")
        rag_service.collection.upsert(
            ids=ids,
            embeddings=embeddings,
            documents=documents,
            metadatas=metadatas
        )
        print(f"Successfully upserted {len(documents)} vectors into ChromaDB.")
    
    db.close()

if __name__ == "__main__":
    ingest_knowledge()
