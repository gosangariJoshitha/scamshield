import os
import chromadb
from pathlib import Path
from typing import List, Dict, Any
from app.services.embedding_service import embedding_service

CHROMA_HOST = os.getenv("CHROMA_HOST", "localhost")
CHROMA_PORT = os.getenv("CHROMA_PORT", "8000")
CHROMA_COLLECTION_NAME = os.getenv("CHROMA_COLLECTION_NAME", "scamshield_knowledge")
RAG_TOP_K = int(os.getenv("RAG_TOP_K", "5"))
RAG_MIN_SIMILARITY = float(os.getenv("RAG_MIN_SIMILARITY", "0.3"))

class RagService:
    def __init__(self):
        configured_path = os.getenv("CHROMA_PERSIST_DIRECTORY", "chroma_db")
        chroma_path = Path(configured_path)
        if not chroma_path.is_absolute():
            chroma_path = Path(__file__).resolve().parents[2] / chroma_path
        self.client = chromadb.PersistentClient(path=str(chroma_path))
        
        self.collection = self.client.get_or_create_collection(
            name=CHROMA_COLLECTION_NAME,
            metadata={"hnsw:space": "cosine"}
        )

    def upsert_knowledge_entry(self, entry: Any) -> None:
        """Keep an approved SQL knowledge entry available to semantic search."""
        indicators = entry.indicators or []
        document = (
            f"Title: {entry.title or ''}\n"
            f"Category: {entry.category or ''}\n"
            f"Pattern: {entry.pattern or ''}\n"
            f"Description: {entry.description or ''}\n"
            f"Indicators: {', '.join(indicators)}\n"
            f"Example: {entry.example or ''}\n"
            f"Safe Action: {entry.safe_action or ''}"
        )
        self.collection.upsert(
            ids=[f"knowledge_{entry.id}"],
            embeddings=[embedding_service.generate_embedding(document)],
            documents=[document],
            metadatas=[{
                "id": entry.id,
                "title": entry.title or "",
                "category": entry.category or "",
                "pattern": entry.pattern or "",
                "safe_action": entry.safe_action or "",
                "source": entry.source or "",
            }],
        )

    def delete_knowledge_entry(self, entry_id: int) -> None:
        self.collection.delete(ids=[f"knowledge_{entry_id}"])
    
    def search(self, text: str, top_k: int = RAG_TOP_K) -> Dict[str, Any]:
        try:
            query_embedding = embedding_service.generate_embedding(text)
            
            results = self.collection.query(
                query_embeddings=[query_embedding],
                n_results=top_k
            )
            
            evidence_list = []
            if not results["ids"] or not results["ids"][0]:
                return {"evidence_status": "NO_RELEVANT_MATCH", "retrieved_evidence": []}
                
            for i in range(len(results["ids"][0])):
                doc_id = results["ids"][0][i]
                distance = results["distances"][0][i]
                similarity = 1.0 - distance
                
                if similarity >= RAG_MIN_SIMILARITY:
                    metadata = results["metadatas"][0][i]
                    evidence_list.append({
                        "knowledge_id": int(metadata.get("id", 0)),
                        "title": metadata.get("title", ""),
                        "category": metadata.get("category", ""),
                        "similarity_score": similarity,
                        "pattern": metadata.get("pattern", ""),
                        "safe_action": metadata.get("safe_action", ""),
                        "source": metadata.get("source", "")
                    })
                    
            if not evidence_list:
                return {"evidence_status": "NO_RELEVANT_MATCH", "retrieved_evidence": []}
                
            evidence_list.sort(key=lambda x: x["similarity_score"], reverse=True)
            
            return {
                "evidence_status": "MATCH_FOUND",
                "retrieved_evidence": evidence_list
            }
        except Exception as e:
            print(f"RAG Retrieval Error: {str(e)}")
            return {"evidence_status": "RETRIEVAL_UNAVAILABLE", "retrieved_evidence": []}

rag_service = RagService()
