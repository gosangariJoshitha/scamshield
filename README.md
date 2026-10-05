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
- **M5:** Explainable LLM Reasoning (Groq)

## Security & Explainability
ScamShield provides an application-level risk assessment. It uses ML to detect patterns and RAG to retrieve similar historical scams. An LLM generates user-friendly explanations WITHOUT making up arbitrary risk scores or fake evidence.

Recommended actions are generated once as a canonical English set, deduplicated, then translated in matching order to Hindi and Telugu. Analysis responses include the canonical actions, their translations, and a detected default language; the results UI switches the displayed translation without regenerating or reordering actions. Missing translations fall back to canonical English and are logged.

User accounts must verify their email address before they can submit analyses. After each completed analysis, ScamShield sends a summary email that excludes the submitted message. HIGH and CRITICAL analyses also create a Jira incident when Jira is configured; Jira is attempted before the email so the incident key can be included. Both integrations run after the analysis is saved and cannot prevent the result from being returned. Delivery and escalation outcomes are stored on the analysis and shown in results/history.

## Getting Started

### Backend
1. `cd backend`
2. `pip install -r requirements.txt`
3. Create a PostgreSQL database. For Supabase, copy the Session pooler URI from Project Settings → Database → Connect and URL-encode special characters in the password.
4. Copy `.env.example` to `.env` and configure keys.
5. Set `DATABASE_URL`, `JWT_SECRET_KEY`, and `ADMIN_EMAIL` / `ADMIN_PASSWORD`. The configured admin account is synchronized at backend startup and is required to use email two-step verification.
6. Set `SENDGRID_API_KEY` and a verified `SENDGRID_SENDER_EMAIL` to enable account verification, sign-in verification, password reset, and per-analysis summary emails. Verification codes expire after 10 minutes and are single-use.
7. Configure Jira using the `JIRA_*` variables; leave `JIRA_ENABLED=false` until the Jira account and project are ready. SMS verification is not currently enabled.
8. Run `alembic upgrade head` to create/update the database schema before starting the API. The API does not create tables automatically.
9. Run `uvicorn main:app --reload`

Never put real credentials in `.env.example`, source control, or chat. Rotate any credential that has been shared or committed. Use the Supabase URI exactly as provided, including the pooler username, and ensure the password is current.

For a database that was previously initialized by an older ScamShield version, do not run the fresh-database migration blindly. Back up the database, compare its schema with the current models, then use `alembic stamp head` only if the existing schema already matches the full application schema. Stamping records the migration revision without executing the migrations.

### Frontend
1. `cd frontend`
2. `npm install`
3. Run `npm run dev`
