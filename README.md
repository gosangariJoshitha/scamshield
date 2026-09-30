# ScamShield - AI-Driven Scam Detection

## Overview
ScamShield is an explainable AI-driven framework for real-time scam detection and risk verification using a multi-stage pipeline: ML Classification -> RAG Semantic Retrieval -> LLM Reasoning -> Risk Engine.

## Structure
- `/frontend` - React/Vite/Tailwind UI
- `/backend` - FastAPI/PostgreSQL API
- `/ml` - Datasets, Models, Vector embeddings

## Architecture
- **M1:** Core Web App & Auth
- **M2:** Multi-channel input processing (Text, Image, PDF, Audio)
- **M3:** ML Classification & Configurable Risk Engine
- **M4:** RAG Semantic Retrieval (ChromaDB)
- **M5:** Explainable LLM Reasoning (OpenRouter)

## Security & Explainability
ScamShield provides an application-level risk assessment. It uses ML to detect patterns and RAG to retrieve similar historical scams. An LLM generates user-friendly explanations WITHOUT making up arbitrary risk scores or fake evidence.

## Getting Started

### Backend
1. `cd backend`
2. `pip install -r requirements.txt`
3. Setup PostgreSQL database 'scamshield'
4. Copy `.env.example` to `.env` and configure keys.
5. Run `alembic upgrade head`
6. Run `uvicorn main:app --reload`

### Frontend
1. `cd frontend`
2. `npm install`
3. Run `npm run dev`
