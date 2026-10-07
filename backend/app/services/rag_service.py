import json
import os
import logging
import re
import time
import chromadb
from pathlib import Path
from typing import List, Dict, Any
from app.services.embedding_service import embedding_service

CHROMA_HOST = os.getenv("CHROMA_HOST", "localhost")
CHROMA_PORT = os.getenv("CHROMA_PORT", "8000")
CHROMA_COLLECTION_NAME = os.getenv("CHROMA_COLLECTION_NAME", "scamshield_knowledge")
RAG_TOP_K = int(os.getenv("RAG_TOP_K", "5"))
RAG_MIN_SIMILARITY = float(os.getenv("RAG_MIN_SIMILARITY", "0.3"))
EXPECTED_MIN_VECTOR_COUNT = 972
SUPPORTED_LANGUAGES = {"en", "hi", "te"}
_WB = r"(?<![^\W_])"
_WE = r"(?![^\W_])"
_SECRET_TERMS = (
    r"(?:otp|one[\s-]?time\s+(?:password|code)|verification\s+code|"
    r"pin|password|ओटीपी|पिन|पासवर्ड|ఓటీపీ|పిన్|పాస్‌వర్డ్)"
)
_REQUEST_VERBS = (
    r"(?:send|share|tell|give|read|provide|reveal|forward|"
    r"enter|confirm|reply\s+with|"
    r"भेजें|भेजो|बताएं|बताओ|दीजिए|दो|చెప్పండి|పంపండి|ఇవ్వండి)"
)
_SECRET_REQUEST_PATTERN = re.compile(
    r"(?:" + _WB + _REQUEST_VERBS + _WE + r".{0,100}" + _WB + _SECRET_TERMS + _WE + r"|"
    + _WB + _SECRET_TERMS + _WE + r".{0,100}" + _WB + _REQUEST_VERBS + _WE + r")",
    re.IGNORECASE | re.UNICODE,
)
_NEGATED_REQUEST_PATTERN = re.compile(
    _WB + r"(?:never|don['’]?t|do\s+not|should\s+not|must\s+not|avoid|"
    r"मत|नहीं|కద్దు|వద్దు)" + _WE + r".{0,100}" + _WB + _REQUEST_VERBS + _WE,
    re.IGNORECASE | re.UNICODE,
)
_GENUINE_CATEGORY_PATTERN = re.compile(
    r"(?:^|[_\s-])genuine(?:$|[_\s-])",
    re.IGNORECASE,
)
logger = logging.getLogger(__name__)


class RagIndexNotReadyError(RuntimeError):
    pass


class RagService:
    def __init__(self):
        configured_path = os.getenv("CHROMA_PERSIST_DIRECTORY", "chroma_db")
        chroma_path = Path(configured_path)
        if not chroma_path.is_absolute():
            chroma_path = Path(__file__).resolve().parents[2] / chroma_path
        self.persist_directory = chroma_path
        self.client = None
        self.collection = None
        self.index_status = "UNAVAILABLE"
        self.vector_count = None
        self._initialize_collection()

    def _initialize_collection(self):
        try:
            self.client = chromadb.PersistentClient(path=str(self.persist_directory))
            self.collection = self.client.get_or_create_collection(
                name=CHROMA_COLLECTION_NAME,
                metadata={"hnsw:space": "cosine"},
            )
        except Exception:
            self.client = None
            self.collection = None
            self.index_status = "UNAVAILABLE"
            self.vector_count = None
            logger.exception(
                "ChromaDB persistence is unavailable at %s.",
                self.persist_directory,
            )
            return
        self.get_index_health()

    def get_index_health(self) -> dict[str, int | str | None]:
        if self.collection is None:
            self.index_status = "UNAVAILABLE"
            self.vector_count = None
        else:
            try:
                count = self.collection.count()
            except Exception:
                self.index_status = "UNAVAILABLE"
                self.vector_count = None
                logger.exception("Unable to read the ChromaDB collection count.")
            else:
                self.vector_count = count
                if count == 0:
                    self.index_status = "EMPTY"
                elif count < EXPECTED_MIN_VECTOR_COUNT:
                    self.index_status = "DEGRADED"
                else:
                    self.index_status = "READY"
        return {
            "status": self.index_status,
            "vector_count": self.vector_count,
            "expected_minimum": EXPECTED_MIN_VECTOR_COUNT,
        }

    def upsert_knowledge_entry(self, entry: Any) -> None:
        """Keep an approved SQL knowledge entry available to semantic search."""
        if self.collection is None:
            raise RagIndexNotReadyError("ChromaDB collection is unavailable.")
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
        self.collection.delete(
            ids=[
                f"knowledge_{entry.id}",
                f"knowledge_{entry.id}_en",
                f"knowledge_{entry.id}_hi",
                f"knowledge_{entry.id}_te",
            ]
        )
        self.collection.upsert(
            ids=[f"knowledge_{entry.id}_und"],
            embeddings=[embedding_service.generate_embedding(document)],
            documents=[document],
            metadatas=[{
                "id": entry.id,
                "title": entry.title or "",
                "category": entry.category or "",
                "pattern": entry.pattern or "",
                "safe_action": entry.safe_action or "",
                "source": entry.source or "",
                "source_type": entry.source_type or "",
                "source_reference": entry.source_reference or "",
                "language": "und",
                "description": entry.description or "",
                "indicators": json.dumps(indicators, ensure_ascii=False),
                "risk_level": entry.risk_level or "",
            }],
        )

    def delete_knowledge_entry(self, entry_id: int) -> None:
        if self.collection is None:
            raise RagIndexNotReadyError("ChromaDB collection is unavailable.")
        self.collection.delete(
            ids=[
                f"knowledge_{entry_id}",
                f"knowledge_{entry_id}_und",
                f"knowledge_{entry_id}_en",
                f"knowledge_{entry_id}_hi",
                f"knowledge_{entry_id}_te",
            ]
        )
    
    def search(
        self,
        text: str,
        top_k: int = RAG_TOP_K,
        language: str = "en",
    ) -> Dict[str, Any]:
        if language not in SUPPORTED_LANGUAGES:
            raise ValueError(f"Unsupported RAG language: {language!r}")
        if top_k < 1:
            raise ValueError("RAG top_k must be at least 1.")

        health = self.get_index_health()
        if health["status"] in {"EMPTY", "UNAVAILABLE"}:
            raise RagIndexNotReadyError(
                f"ChromaDB index is {health['status'].lower()}."
            )

        embedding_ms = None
        retrieval_ms = None
        candidate_limit = max(top_k * 5, top_k)
        embedding_started = time.perf_counter()
        retrieval_started = None
        try:
            query_embedding = embedding_service.generate_embedding(text)
            embedding_ms = (time.perf_counter() - embedding_started) * 1000

            retrieval_started = time.perf_counter()
            evidence_list = []
            seen_ids = set()

            self._append_results(
                evidence_list,
                seen_ids,
                query_embedding,
                candidate_limit,
                {
                    "$and": [
                        {"language": language},
                        {"source_type": {"$ne": "EXTERNAL_GUIDANCE"}},
                    ]
                },
            )
            if len(evidence_list) < candidate_limit:
                self._append_results(
                    evidence_list,
                    seen_ids,
                    query_embedding,
                    candidate_limit,
                    {
                        "$and": [
                            {"language": {"$ne": language}},
                            {"source_type": {"$ne": "EXTERNAL_GUIDANCE"}},
                        ]
                    },
                )
            if len(evidence_list) < candidate_limit:
                self._append_results(
                    evidence_list,
                    seen_ids,
                    query_embedding,
                    candidate_limit,
                    {
                        "$and": [
                            {"language": language},
                            {"source_type": "EXTERNAL_GUIDANCE"},
                        ]
                    },
                )
            if len(evidence_list) < candidate_limit:
                self._append_results(
                    evidence_list,
                    seen_ids,
                    query_embedding,
                    candidate_limit,
                    {"source_type": "EXTERNAL_GUIDANCE"},
                )

            retrieval_ms = (time.perf_counter() - retrieval_started) * 1000

            if not evidence_list:
                return {
                    "evidence_status": "NO_RELEVANT_MATCH",
                    "retrieved_evidence": [],
                    "timings": {
                        "embedding_ms": embedding_ms,
                        "retrieval_ms": retrieval_ms,
                    },
                }
            evidence_list = self._rerank_results(text, evidence_list)
            return {
                "evidence_status": "MATCH_FOUND",
                "retrieved_evidence": evidence_list[:top_k],
                "timings": {
                    "embedding_ms": embedding_ms,
                    "retrieval_ms": retrieval_ms,
                },
            }
        except Exception:
            if embedding_ms is None:
                embedding_ms = (time.perf_counter() - embedding_started) * 1000
            if retrieval_started is not None and retrieval_ms is None:
                retrieval_ms = (time.perf_counter() - retrieval_started) * 1000
            logger.exception("RAG retrieval is unavailable.")
            return {
                "evidence_status": "RETRIEVAL_UNAVAILABLE",
                "retrieved_evidence": [],
                "timings": {
                    "embedding_ms": embedding_ms,
                    "retrieval_ms": retrieval_ms,
                },
            }

    def _append_results(
        self,
        evidence_list: list[dict[str, Any]],
        seen_ids: set[str],
        query_embedding: list[float],
        candidate_limit: int,
        where: dict[str, Any],
    ) -> None:
        remaining = candidate_limit - len(evidence_list)
        if remaining <= 0:
            return
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=candidate_limit,
            where=where,
            include=["distances", "metadatas", "documents"],
        )
        if not results["ids"] or not results["ids"][0]:
            return
        candidates = []
        documents = results.get("documents", [[]])[0]
        for index, (vector_id, distance, metadata) in enumerate(zip(
            results["ids"][0],
            results["distances"][0],
            results["metadatas"][0],
        )):
            if vector_id in seen_ids:
                continue
            similarity = 1.0 - distance
            if similarity < RAG_MIN_SIMILARITY:
                continue
            metadata = metadata or {}
            document = documents[index] if index < len(documents) else ""
            raw_indicators = metadata.get("indicators", [])
            if isinstance(raw_indicators, str):
                try:
                    raw_indicators = json.loads(raw_indicators)
                except json.JSONDecodeError:
                    raw_indicators = [
                        item.strip()
                        for item in raw_indicators.split(",")
                        if item.strip()
                    ]
            if not isinstance(raw_indicators, list):
                raw_indicators = []
            candidates.append({
                "vector_id": vector_id,
                "knowledge_id": int(metadata.get("id", 0)),
                "title": metadata.get("title", ""),
                "category": metadata.get("category", ""),
                "similarity_score": similarity,
                "pattern": metadata.get("pattern", ""),
                "description": metadata.get("description")
                or self._document_field(document, "Description"),
                "indicators": raw_indicators,
                "risk_level": metadata.get("risk_level") or None,
                "safe_action": metadata.get("safe_action", ""),
                "source": metadata.get("source", ""),
                "language": metadata.get("language", "und"),
                "source_type": metadata.get("source_type", ""),
            })
        candidates.sort(key=lambda item: item["similarity_score"], reverse=True)
        for candidate in candidates[:remaining]:
            seen_ids.add(candidate["vector_id"])
            del candidate["vector_id"]
            evidence_list.append(candidate)

    @staticmethod
    def _document_field(document: str, field_name: str) -> str:
        prefix = f"{field_name}:"
        for line in document.splitlines():
            if line.startswith(prefix):
                return line[len(prefix):].strip()
        return ""

    @staticmethod
    def _rerank_results(
        query_text: str,
        candidates: list[dict[str, Any]],
    ) -> list[dict[str, Any]]:
        sentences = re.split(r"(?<=[.!?।])\s+|\n+", query_text)
        requests_secret = any(
            _SECRET_REQUEST_PATTERN.search(sentence)
            and not _NEGATED_REQUEST_PATTERN.search(sentence)
            for sentence in sentences
        )
        if requests_secret:
            scam_candidates = [
                item
                for item in candidates
                if not _GENUINE_CATEGORY_PATTERN.search(
                    item.get("category", "")
                )
            ]
            if scam_candidates:
                candidates = scam_candidates
        return candidates

rag_service = RagService()
