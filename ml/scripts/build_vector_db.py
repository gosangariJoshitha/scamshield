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
    
    # 1. Load data from JSON if KnowledgeEntry is empty
    count = db.query(KnowledgeEntry).count()
    if count == 0:
        json_path = os.path.join(backend_dir, 'data', 'knowledgebase_100_articles.json')
        if os.path.exists(json_path):
            print(f"Loading knowledge base from {json_path}")
            with open(json_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            for article in data.get("articles", []):
                if article.get("type") == "scam_pattern":
                    indicators = article.get("common_indicators", [])
                    recommended_actions = article.get("recommended_action", [])
                    safe_action = " ".join(recommended_actions) if recommended_actions else ""
                    
                    entry = KnowledgeEntry(
                        title=article.get("title", ""),
                        pattern=article.get("pattern", ""),
                        category=article.get("pattern", ""),
                        description=article.get("overview", ""),
                        indicators=indicators,
                        example="",
                        safe_action=safe_action,
                        risk_level="HIGH",
                        source="ScamShield Curated Database",
                        status="ACTIVE"
                    )
                    db.add(entry)
            db.commit()
            print("Imported articles to PostgreSQL.")
        else:
            print("JSON not found at path")
    
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
