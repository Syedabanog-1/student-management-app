# Tasks: Student Management CRUD Application

**Input**: Design documents from `/specs/001-student-crud-app/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/students-api.yaml

**Tests**: Tests are NOT explicitly requested in the specification. Test tasks are omitted per guidelines.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Web app**: `backend/` for FastAPI, `frontend/` for Next.js
- All paths are relative to repository root

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create project structure and initialize both frontend and backend projects

**Owner**: Lead Architect Agent

- [X] T001 Create backend directory structure with app/, app/models/, app/api/, tests/ in backend/
- [X] T002 Create frontend directory structure with src/app/, src/components/, src/components/ui/, src/hooks/, src/services/, src/types/ in frontend/
- [X] T003 [P] Create root .gitignore with Python, Node.js, IDE, and environment file patterns
- [X] T004 [P] Create backend/requirements.txt with fastapi, uvicorn, sqlmodel, pydantic[email], python-dotenv dependencies
- [X] T005 [P] Create frontend/package.json with next, react, react-dom, @tanstack/react-query, typescript, tailwindcss dependencies
- [X] T006 [P] Create backend/.env.example with DATABASE_URL and ALLOWED_ORIGINS variables
- [X] T007 [P] Create frontend/.env.example with NEXT_PUBLIC_API_URL variable
- [X] T008 [P] Create root .env.example documenting all required environment variables

**Checkpoint**: Project skeleton ready - proceed to foundational phase

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**Owner**: Backend Agent (FastAPI) + Frontend Agent (Next.js) + DevOps Agent

### Backend Foundation

- [X] T009 Create backend/app/__init__.py as empty package marker
- [X] T010 Create backend/app/config.py with Settings class using pydantic-settings for DATABASE_URL and ALLOWED_ORIGINS
- [X] T011 Create backend/app/database.py with SQLite engine, create_db_and_tables(), and get_session() dependency
- [X] T012 Create backend/app/models/__init__.py exporting all model classes
- [X] T013 Create backend/app/models/student.py with StudentBase, Student(table=True), StudentCreate, StudentUpdate, StudentPatch, StudentRead models per data-model.md
- [X] T014 Create backend/app/exceptions.py with custom exception handlers for IntegrityError (409), ValidationError (400), and generic errors
- [X] T015 Create backend/app/api/__init__.py as empty package marker
- [X] T016 Create backend/app/main.py with FastAPI app, CORS middleware, lifespan for DB init, health endpoint, and router includes

### Frontend Foundation

- [X] T017 [P] Create frontend/tsconfig.json with strict TypeScript configuration and path aliases
- [X] T018 [P] Create frontend/tailwind.config.ts with content paths and custom glassmorphism theme extensions
- [X] T019 [P] Create frontend/next.config.js with API rewrites if needed
- [X] T020 [P] Create frontend/src/types/student.ts with Student, StudentCreate, StudentUpdate, StudentPatch, ApiError interfaces per data-model.md
- [X] T021 Create frontend/src/app/globals.css with Tailwind directives and custom glassmorphism utility classes (.glass, .glass-dark, gradients)
- [X] T022 Create frontend/src/services/api.ts with base fetch wrapper, error handling, and typed API methods (getStudents, createStudent, updateStudent, patchStudent, deleteStudent)
- [X] T023 Create frontend/src/app/layout.tsx with QueryClientProvider, html/body structure, and global styles import

### UI Component Foundation

- [X] T024 [P] Create frontend/src/components/ui/GlassCard.tsx with backdrop-blur, semi-transparent background, and border styling
- [X] T025 [P] Create frontend/src/components/ui/Button.tsx with variants (primary, secondary, danger), sizes, loading state, and disabled state
- [X] T026 [P] Create frontend/src/components/ui/Input.tsx with label, error message display, and glassmorphism styling
- [X] T027 [P] Create frontend/src/components/ui/Modal.tsx with overlay, glass panel, close button, and body/footer slots
- [X] T028 [P] Create frontend/src/components/ui/Toast.tsx with success/error variants and auto-dismiss functionality

### DevOps Foundation

- [X] T029 [P] Create docker-compose.yml with backend and frontend services, port mappings (8000, 3000), and environment variables
- [X] T030 [P] Create root README.md with project overview, quick start instructions, and links to quickstart.md

**Checkpoint**: Foundation ready - all user stories can now begin implementation

---

## Phase 3: User Story 1 - Add New Student (Priority: P1)

**Goal**: Enable administrators to add new students with validation and duplicate detection

**Owner**: Backend Agent + Frontend Agent

**Independent Test**: Fill out add student form, submit, verify student appears in list with success notification

### Backend Implementation for US1

- [X] T031 [US1] Implement POST /api/students endpoint in backend/app/api/students.py with StudentCreate validation, IntegrityError handling for duplicate email/roll_number (409), and StudentRead response (201)
- [X] T032 [US1] Add students router to backend/app/main.py with prefix "/api/students"

### Frontend Implementation for US1

- [X] T033 [US1] Create frontend/src/hooks/useStudents.ts with useCreateStudent mutation using React Query, optimistic updates, and error handling
- [X] T034 [US1] Create frontend/src/components/StudentForm.tsx with name, email, roll_number inputs, client-side validation, submit handler, loading state, and error display
- [X] T035 [US1] Create frontend/src/app/page.tsx with basic layout, "Add Student" button, StudentForm modal integration, and toast notifications
- [X] T036 [US1] Add form validation in StudentForm.tsx: required fields, email format regex, roll_number alphanumeric pattern

**Checkpoint**: User Story 1 complete - can add students with full validation and error handling

---

## Phase 4: User Story 2 - View and Search Students (Priority: P2)

**Goal**: Display all students in glassmorphism cards with real-time search filtering

**Owner**: Backend Agent + Frontend Agent

**Independent Test**: Add sample students, use search bar to filter by name/email/roll_number, verify results update in real-time

### Backend Implementation for US2

- [X] T037 [US2] Implement GET /api/students endpoint in backend/app/api/students.py with optional search query parameter, case-insensitive ILIKE filtering on name/email/roll_number, and list response
- [X] T038 [US2] Implement GET /api/students/{id} endpoint in backend/app/api/students.py with 404 handling for not found

### Frontend Implementation for US2

- [X] T039 [US2] Add useStudents query hook in frontend/src/hooks/useStudents.ts with search parameter, debouncing, and caching configuration
- [X] T040 [US2] Create frontend/src/components/SearchBar.tsx with input field, search icon, debounced onChange (300ms), and clear button
- [X] T041 [US2] Create frontend/src/components/StudentCard.tsx with GlassCard wrapper displaying name, email, roll_number, and action buttons (Edit, Delete)
- [X] T042 [US2] Create frontend/src/components/StudentList.tsx with search integration, loading skeleton, empty state message, and responsive grid layout
- [X] T043 [US2] Update frontend/src/app/page.tsx to include SearchBar and StudentList components with connected state

**Checkpoint**: User Story 2 complete - can view all students and search/filter in real-time

---

## Phase 5: User Story 3 - Update Student Information (Priority: P3)

**Goal**: Enable editing existing students with PUT (full) and PATCH (partial) updates

**Owner**: Backend Agent + Frontend Agent

**Independent Test**: Click edit on a student, modify fields, save, verify changes persist and display correctly

### Backend Implementation for US3

- [X] T044 [US3] Implement PUT /api/students/{id} endpoint in backend/app/api/students.py with full StudentUpdate validation, 404 handling, IntegrityError for duplicates (409), and updated_at timestamp update
- [X] T045 [US3] Implement PATCH /api/students/{id} endpoint in backend/app/api/students.py with StudentPatch, exclude_unset=True for partial updates, 404 handling, and IntegrityError handling

### Frontend Implementation for US3

- [X] T046 [US3] Add useUpdateStudent and usePatchStudent mutations in frontend/src/hooks/useStudents.ts with cache invalidation
- [X] T047 [US3] Update frontend/src/components/StudentForm.tsx to accept optional initialData prop for edit mode, populate fields, and call appropriate update mutation
- [X] T048 [US3] Update frontend/src/components/StudentCard.tsx Edit button to open StudentForm modal in edit mode with student data
- [X] T049 [US3] Add edit modal state management in frontend/src/app/page.tsx with selectedStudent state and modal visibility

**Checkpoint**: User Story 3 complete - can edit students with both full and partial updates

---

## Phase 6: User Story 4 - Delete Student (Priority: P4)

**Goal**: Enable deletion with confirmation dialog to prevent accidental data loss

**Owner**: Backend Agent + Frontend Agent

**Independent Test**: Click delete on a student, see confirmation dialog, confirm, verify student removed from list

### Backend Implementation for US4

- [X] T050 [US4] Implement DELETE /api/students/{id} endpoint in backend/app/api/students.py with 404 handling and success message response

### Frontend Implementation for US4

- [X] T051 [US4] Add useDeleteStudent mutation in frontend/src/hooks/useStudents.ts with cache invalidation on success
- [X] T052 [US4] Create frontend/src/components/DeleteConfirmDialog.tsx with Modal, warning message, student name display, Cancel and Confirm buttons
- [X] T053 [US4] Update frontend/src/components/StudentCard.tsx Delete button to open DeleteConfirmDialog with student data
- [X] T054 [US4] Add delete confirmation state management in frontend/src/app/page.tsx with studentToDelete state and dialog visibility

**Checkpoint**: User Story 4 complete - can delete students with confirmation protection

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final refinements, accessibility, and production readiness

**Owner**: All Agents (coordinated by Lead Architect)

### Error Handling & UX

- [X] T055 [P] Add global error boundary in frontend/src/app/layout.tsx for unhandled React errors
- [X] T056 [P] Add loading skeleton components in frontend/src/components/StudentList.tsx for initial load state
- [X] T057 [P] Add empty state component in frontend/src/components/StudentList.tsx with "No students yet" message and Add Student CTA

### Accessibility & Responsiveness

- [X] T058 [P] Add ARIA labels and keyboard navigation to all interactive elements in frontend/src/components/
- [X] T059 [P] Add responsive breakpoints in frontend/src/app/page.tsx for mobile (1 column), tablet (2 columns), desktop (3 columns) grid

### Documentation

- [X] T060 [P] Create backend/README.md with setup instructions, API documentation link, and development commands
- [X] T061 [P] Create frontend/README.md with setup instructions, component overview, and development commands

### Backend Tests (Optional Enhancement)

- [X] T062 [P] Create backend/tests/__init__.py as empty package marker
- [X] T063 [P] Create backend/tests/conftest.py with test database fixture and test client fixture
- [X] T064 [P] Create backend/tests/test_students_api.py with tests for all CRUD endpoints including error cases

**Checkpoint**: All polish complete - application production-ready

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) ─────────────────────────────────────────┐
                                                          │
Phase 2 (Foundational) ──────────────────────────────────┤
    ├── Backend Foundation (T009-T016)                   │
    ├── Frontend Foundation (T017-T023)                  │
    ├── UI Components (T024-T028)                        │
    └── DevOps (T029-T030)                               │
                                                          ▼
┌─────────────────────────────────────────────────────────┘
│
├── Phase 3 (US1: Add Student) ──► T031-T036
│       │
├── Phase 4 (US2: View/Search) ──► T037-T043
│       │
├── Phase 5 (US3: Update) ───────► T044-T049
│       │
├── Phase 6 (US4: Delete) ───────► T050-T054
│       │
└── Phase 7 (Polish) ────────────► T055-T064
```

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 completion. No dependencies on other stories.
- **User Story 2 (P2)**: Depends on Phase 2. Can run in parallel with US1 (different API endpoints).
- **User Story 3 (P3)**: Depends on Phase 2. Uses StudentForm from US1 (can share component).
- **User Story 4 (P4)**: Depends on Phase 2. Uses StudentCard from US2 (shared component).

### Within Each User Story

1. Backend endpoints first
2. Frontend hooks after backend
3. UI components after hooks
4. Page integration last

### Parallel Opportunities

**Phase 1** - All tasks after T002 can run in parallel:
```
T003 ─┬─ T004 ─┬─ T005 ─┬─ T006 ─┬─ T007 ─┬─ T008
```

**Phase 2** - Backend and Frontend foundations can run in parallel:
```
Backend: T009 → T010 → T011 → T012 → T013 → T14 → T15 → T016
                  ║ (parallel)
Frontend: T017 ─┬─ T018 ─┬─ T019 ─┬─ T020 → T021 → T022 → T023
                │        │        │
UI:        T024 ─┬─ T025 ─┬─ T026 ─┬─ T027 ─┬─ T028
                                    ║ (parallel)
DevOps:                        T029 ─┬─ T030
```

**User Stories** - Can overlap if different developers:
```
US1 Backend (T031-T032) can run parallel with US2 Backend (T037-T038)
US1 Frontend needs US1 Backend complete
US2 Frontend needs US2 Backend complete
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (~15 min)
2. Complete Phase 2: Foundational (~45 min)
3. Complete Phase 3: User Story 1 (~30 min)
4. **STOP and VALIDATE**: Test adding students with validation
5. Deploy/demo if ready - minimal but functional

### Incremental Delivery

| Increment | Stories Complete | Capability |
|-----------|------------------|------------|
| MVP | US1 | Can add students |
| +Search | US1, US2 | Can add and find students |
| +Edit | US1, US2, US3 | Full data management |
| +Delete | US1-US4 | Complete CRUD |
| +Polish | All | Production-ready |

### Parallel Team Strategy

With 2+ developers:

**Developer A (Backend)**:
- Phase 2: T009-T016
- US1: T031-T032
- US2: T037-T038
- US3: T044-T045
- US4: T050

**Developer B (Frontend)**:
- Phase 2: T017-T028
- US1: T033-T036 (after T031-T032 complete)
- US2: T039-T043 (after T037-T038 complete)
- US3: T046-T049
- US4: T051-T054

**Developer C (DevOps)** or shared:
- Phase 2: T029-T030
- Phase 7: T055-T064

---

## Task Summary

| Phase | Task Range | Count | Parallel Tasks | Status |
|-------|------------|-------|----------------|--------|
| 1. Setup | T001-T008 | 8 | 6 | ✅ Complete |
| 2. Foundational | T009-T030 | 22 | 12 | ✅ Complete |
| 3. US1 Add | T031-T036 | 6 | 0 | ✅ Complete |
| 4. US2 View/Search | T037-T043 | 7 | 0 | ✅ Complete |
| 5. US3 Update | T044-T049 | 6 | 0 | ✅ Complete |
| 6. US4 Delete | T050-T054 | 5 | 0 | ✅ Complete |
| 7. Polish | T055-T064 | 10 | 10 | ✅ Complete |
| **Total** | T001-T064 | **64** | **28** | **✅ ALL COMPLETE** |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable after foundational phase
- Verify each checkpoint before proceeding to next phase
- Commit after each task or logical group
- All tasks include exact file paths for LLM execution
