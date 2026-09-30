# ScamShield - Milestone 1

## Overview
ScamShield is an explainable AI-driven framework for real-time scam detection and risk verification. Milestone 1 covers the fundamental web application skeleton, including the landing page, protected dashboard, and user authentication setup with FastAPI and React.

## Structure
- `/frontend` - React/Vite/Tailwind UI
- `/backend` - FastAPI/PostgreSQL API
- `/ml` - (Future) Datasets, Models, ChromaDB
- `/uploads` - Target directory for file uploads

## Getting Started

### Backend
1. `cd backend`
2. `pip install -r requirements.txt`
3. Setup PostgreSQL database 'scamshield'
4. Run `uvicorn main:app --reload`

### Frontend
1. `cd frontend`
2. `npm install`
3. Run `npm run dev`
