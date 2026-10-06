# M6/M7 engineering freeze criteria — provisional

> Engineering freeze criteria derived from current implemented scope; requires
> project-owner/team approval if an external authoritative specification exists.

## Source search and limitation

The repository README describes M1–M5 and M8, and the available project docs
cover the ML pipeline and dataset. No authoritative M6/M7 acceptance document,
PRD, or milestone specification was found. This file therefore records only
the behavior already represented by the current code and tests. It does not
assert that the original project milestones are complete.

## Provisional M6: human review and escalation

| Requirement | Implementation | Test/evidence | Status |
|---|---|---|---|
| Persist one review case for an automatically escalated analysis and retain an audit trail of review transitions. | `backend/app/services/escalation_service.py`, review models, and `backend/reviews.py` | `backend/tests/test_review_start.py`; migration and review API tests | Implemented scope; owner approval required |
| Keep Jira escalation restricted to automatically escalated HIGH/CRITICAL cases and avoid duplicate issues for the same case. | `backend/app/services/jira_service.py` | `backend/tests/test_jira_service.py`; provider-mocked verification | Implemented scope; live provider status reported separately |
| Preserve analysis results if human-review/Jira delivery fails. | Analysis pipeline and durable notification outbox | `backend/tests/test_analysis_notifications.py` | Implemented scope; owner approval required |

## Provisional M7: admin operations and monitoring

| Requirement | Implementation | Test/evidence | Status |
|---|---|---|---|
| Restrict administrative review, user, analysis, knowledge, audit, and monitoring APIs to active administrators. | `backend/admin.py`, `backend/monitoring.py`, `backend/reviews.py` | `backend/tests/test_auth_roles.py` and admin API tests | Implemented scope; owner approval required |
| Expose measured model, database, RAG, and channel status without presenting an empty/unavailable RAG index as healthy. | Admin monitoring endpoints | `backend/tests/test_rag_readiness.py` and monitoring tests | Implemented scope; owner approval required |
| Keep the admin UI buildable and exercise supported analysis/authentication API paths with repeatable tests. | `frontend/` and backend API integration tests | Frontend build/lint plus backend suite; browser E2E is not claimed | Partial; browser-level E2E requires separate approval/coverage |

## Approval gate

Before labeling M6 or M7 complete, the project owner/team should confirm that
these inferred scopes match the intended milestone definitions and resolve any
missing external requirements. A passing implementation test is evidence for
the listed behavior only; it is not a substitute for that approval.
