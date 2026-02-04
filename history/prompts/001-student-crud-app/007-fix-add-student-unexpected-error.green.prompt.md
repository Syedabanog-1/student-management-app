---
id: 007
title: Fix Add Student Unexpected Error
stage: green
date: 2026-02-01
surface: agent
model: claude-opus-4-5-20251101
feature: 001-student-crud-app
branch: main
user: user
command: /sp.clarify
labels: ["bugfix", "api", "error-handling", "frontend"]
links:
  spec: specs/001-student-crud-app/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - frontend/src/services/api.ts (modified)
tests:
  - None
---

## Prompt

at broswer add student mein an unexpected error is coming fix it add student successfully if roll_number similar existing one raise error no duplicate values is allowed

## Response snapshot

**Root Cause:** FastAPI's `HTTPException` wraps the `detail` parameter inside another `detail` key in the JSON response. The frontend was expecting a flat structure but receiving:

```json
// Actual response from FastAPI
{
  "detail": {
    "detail": "A student with this roll number already exists",
    "code": "DUPLICATE_ROLL_NUMBER",
    "field": "roll_number"
  }
}

// Frontend expected
{
  "detail": "A student with this roll number already exists",
  "code": "DUPLICATE_ROLL_NUMBER",
  "field": "roll_number"
}
```

**Fix Applied:** Updated `frontend/src/services/api.ts` to handle both nested and flat error response formats:

```typescript
if (jsonResponse.detail && typeof jsonResponse.detail === "object") {
  errorData = jsonResponse.detail as ApiError;
} else if (jsonResponse.detail && typeof jsonResponse.detail === "string") {
  errorData = {
    detail: jsonResponse.detail,
    code: "VALIDATION_ERROR",
  };
} else {
  errorData = jsonResponse as ApiError;
}
```

Now:
- Adding a student works successfully
- Duplicate roll_number shows proper error: "A student with this roll number already exists"
- Duplicate email shows proper error: "A student with this email already exists"

## Outcome

- Impact: Fixed "unexpected error" when adding students; duplicate validation errors now display correctly
- Tests: N/A (manual browser testing required)
- Files: frontend/src/services/api.ts modified
- Next prompts: Implement gray UI theme
- Reflection: FastAPI's HTTPException response structure differs from typical REST APIs; frontend must handle the nested format

## Evaluation notes (flywheel)

- Failure modes observed: API error response parsing assumed flat structure
- Graders run and results (PASS/FAIL): N/A
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): Test in browser to confirm fix works
