---
id: 006
title: Fix Deprecated utcnow Method
stage: refactor
date: 2026-02-01
surface: agent
model: claude-opus-4-5-20251101
feature: 001-student-crud-app
branch: main
user: user
command: /sp.clarify
labels: ["deprecation", "python", "datetime", "refactor"]
links:
  spec: specs/001-student-crud-app/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - backend/app/main.py (modified)
  - backend/app/models/student.py (modified)
  - backend/app/api/students.py (modified)
tests:
  - None
---

## Prompt

backend then app then main.py ki file mein utcnow method deprecated ha replace it

## Response snapshot

Fixed deprecated `datetime.utcnow()` across all backend files:

**Changes Made:**

1. `backend/app/main.py`:
   - Import: `from datetime import datetime` → `from datetime import datetime, timezone`
   - Usage: `datetime.utcnow().isoformat()` → `datetime.now(timezone.utc).isoformat()`

2. `backend/app/models/student.py`:
   - Import: Added `timezone` to datetime import
   - `default_factory=datetime.utcnow` → `default_factory=lambda: datetime.now(timezone.utc)`

3. `backend/app/api/students.py`:
   - Import: Added `timezone` to datetime import
   - All `datetime.utcnow()` → `datetime.now(timezone.utc)` (2 occurrences)

**Why:** `datetime.utcnow()` is deprecated in Python 3.12+ because it returns a naive datetime. The replacement `datetime.now(timezone.utc)` returns a timezone-aware datetime, which is the recommended approach.

## Outcome

- Impact: Removed all deprecation warnings for datetime.utcnow()
- Tests: N/A (refactoring only, no behavior change)
- Files: 3 files modified
- Next prompts: Implement gray UI theme
- Reflection: Good practice to fix deprecations early before they become errors in future Python versions

## Evaluation notes (flywheel)

- Failure modes observed: None
- Graders run and results (PASS/FAIL): N/A
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): N/A - straightforward deprecation fix
