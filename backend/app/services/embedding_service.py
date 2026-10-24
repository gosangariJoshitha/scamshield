import os
import threading
from typing import Optional
from sentence_transformers import SentenceTransformer

# Load embedding model, defaulting to a multilingual model suitable for EN, HI, TE
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "paraphrase-multilingual-MiniLM-L12-v2")

class EmbeddingService:
    def __init__(self):
        self._model: Optional[SentenceTransformer] = None
        self._lock = threading.Lock()
    
    @property
    def model(self) -> SentenceTransformer:
        if self._model is None:
            with self._lock:
                if self._model is None:
                    self._model = SentenceTransformer(EMBEDDING_MODEL)
        return self._model
    
    def generate_embedding(self, text: str) -> list[float]:
        embedding = self.model.encode(text)
        return embedding.tolist()
    
    def generate_embeddings(self, texts: list[str]) -> list[list[float]]:
        embeddings = self.model.encode(texts)
        return embeddings.tolist()
        
embedding_service = EmbeddingService()
