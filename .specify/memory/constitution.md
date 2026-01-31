<!--
  Sync Impact Report
  ==================
  Version change: 0.0.0 → 1.0.0 (MAJOR - initial constitution)

  Modified principles: N/A (initial creation)

  Added sections:
  - Core Principles (8 principles for multi-agent architecture)
  - Multi-Agent Architecture (4 specialized agents defined)
  - Development Workflow (agent collaboration protocol)
  - Governance (amendment and compliance rules)

  Removed sections: N/A (initial creation)

  Templates requiring updates:
  - plan-template.md: ✅ Compatible (Constitution Check section aligns)
  - spec-template.md: ✅ Compatible (no changes required)
  - tasks-template.md: ✅ Compatible (web app structure documented)

  Follow-up TODOs: None
-->

# Student Management App Constitution

## Core Principles

### I. Clean Architecture Separation

The codebase MUST maintain strict separation between frontend and backend concerns:
- `backend/` directory contains all FastAPI server code, models, and API logic
- `frontend/` directory contains all Next.js client code, components, and UI logic
- Shared type definitions and contracts MUST be documented in `specs/` but implemented separately
- No direct file imports across the frontend/backend boundary

**Rationale**: Clean separation enables independent development, testing, and deployment of each layer while enforcing clear API contracts.

### II. API-First Development

All features MUST be designed API-first before implementation:
- Backend endpoints MUST be defined with OpenAPI/JSON Schema contracts
- Frontend MUST consume only documented API endpoints
- Contract changes MUST be versioned and backward-compatible where possible
- IntegrityError and validation errors MUST return structured JSON responses

**Rationale**: API-first ensures frontend and backend can develop in parallel with well-defined integration points.

### III. Data Integrity (NON-NEGOTIABLE)

Database operations MUST enforce data integrity at all levels:
- `email` and `roll_number` fields MUST have unique constraints at the database level
- SQLModel MUST define validators for email format and roll_number patterns
- All database operations MUST use transactions with proper rollback on failure
- IntegrityError exceptions MUST be caught and converted to user-friendly error responses

**Rationale**: Data integrity violations corrupt the system state; enforcement at the database level is the last line of defense.

### IV. Comprehensive CRUD Operations

The Student entity MUST support complete CRUD with the following operations:
- **GET** `/students` - List all students with search/filter support (by name, email, roll_number)
- **GET** `/students/{id}` - Retrieve single student by ID
- **POST** `/students` - Create new student with validation
- **PUT** `/students/{id}` - Full update (replace all fields)
- **PATCH** `/students/{id}` - Partial update (modify specific fields)
- **DELETE** `/students/{id}` - Remove student with confirmation

**Rationale**: Full CRUD coverage ensures the application can handle all standard data management operations.

### V. Error Handling Consistency

All errors MUST follow a consistent structure across the stack:
- Backend MUST return errors as `{"detail": "message", "code": "ERROR_CODE", "field": "optional_field"}`
- Frontend MUST display errors contextually (field-level for validation, toast for system errors)
- HTTP status codes MUST be semantic: 400 for validation, 404 for not found, 409 for conflicts, 500 for server errors
- All exceptions MUST be logged with stack traces in development, sanitized in production

**Rationale**: Consistent error handling improves debugging, user experience, and system reliability.

### VI. Modern UI Standards

The frontend MUST implement modern Glassmorphism UI design:
- Glass-effect cards with `backdrop-filter: blur()` and semi-transparent backgrounds
- Consistent color scheme with subtle gradients and soft shadows
- Responsive design working on mobile (320px) through desktop (1920px+)
- Accessible components meeting WCAG 2.1 AA standards (contrast, keyboard navigation)
- Loading states and skeleton screens for async operations

**Rationale**: Modern, polished UI increases user trust and adoption while accessibility ensures inclusivity.

### VII. State Management Discipline

Frontend state MUST be managed predictably:
- Server state (student data) MUST use React Query or SWR for caching and synchronization
- Form state MUST use controlled components with proper validation feedback
- Optimistic updates SHOULD be used for better UX with rollback on failure
- No prop drilling beyond 2 levels; use context or state library for shared state

**Rationale**: Disciplined state management prevents bugs, improves performance, and makes the codebase maintainable.

### VIII. Production-Ready Structure

The application MUST be production-ready from the start:
- Environment variables for all configuration (database URL, API URL, secrets)
- `.env.example` files documenting required variables (never commit actual `.env`)
- Docker Compose for local development with consistent environments
- Health check endpoints for both frontend and backend
- Structured logging with request IDs for traceability

**Rationale**: Production-readiness from day one reduces deployment friction and operational incidents.

## Multi-Agent Architecture

This project employs a collaborative multi-agent approach with specialized responsibilities:

### Lead Architect Agent

**Role**: System design authority and cross-cutting concerns owner

**Skills**:
- Define and enforce clean architecture boundaries
- Design folder structure and module organization
- Review architectural decisions for consistency
- Resolve conflicts between agent recommendations
- Ensure constitution compliance in all implementations

**Artifacts Owned**: `specs/*/plan.md`, `history/adr/`, folder structure decisions

### Backend Agent (FastAPI)

**Role**: Server-side implementation specialist

**Skills**:
- SQLModel + SQLite database setup and configuration
- Student model with unique constraints (email, roll_number)
- Full CRUD API implementation (GET with search, POST, PUT, PATCH, DELETE)
- IntegrityError handling with transaction rollback
- Request validation using Pydantic models
- Structured error responses

**Artifacts Owned**: `backend/` directory, API contracts in `specs/*/contracts/`

**Technology Stack**:
- Python 3.11+
- FastAPI framework
- SQLModel ORM (SQLAlchemy + Pydantic)
- SQLite database
- pytest for testing

### Frontend Agent (Next.js)

**Role**: Client-side implementation specialist

**Skills**:
- Next.js 14+ App Router setup
- API integration with fetch/axios and error handling
- State management (React Query recommended)
- Glassmorphism UI component library
- Student CRUD interface (add, update, search, delete)
- Form validation and user feedback
- Responsive and accessible design

**Artifacts Owned**: `frontend/` directory, UI component specifications

**Technology Stack**:
- Node.js 20+
- Next.js 14+ (App Router)
- TypeScript
- Tailwind CSS
- React Query or SWR

### DevOps/Integration Agent

**Role**: Environment, deployment, and cross-system integration specialist

**Skills**:
- Environment setup and configuration management
- API-frontend wiring and CORS configuration
- Error handling consistency validation across stack
- Docker and Docker Compose configuration
- Production-ready structure enforcement
- CI/CD pipeline setup (when needed)

**Artifacts Owned**: `docker-compose.yml`, `.env.example`, deployment configs, integration tests

## Development Workflow

### Agent Collaboration Protocol

1. **Specification Phase**: Lead Architect defines requirements in `spec.md`
2. **Planning Phase**: Lead Architect creates `plan.md` with agent assignments
3. **Contract Phase**: Backend Agent and Frontend Agent agree on API contracts
4. **Implementation Phase**: Agents work in parallel on their domains
5. **Integration Phase**: DevOps Agent wires components and validates consistency
6. **Review Phase**: Lead Architect reviews for constitution compliance

### Handoff Requirements

When passing work between agents:
- Backend → Frontend: Provide OpenAPI spec or contract definition
- Frontend → Backend: Provide expected request/response examples
- Any Agent → DevOps: Provide environment variable requirements
- DevOps → All: Provide `.env.example` updates and setup instructions

### Conflict Resolution

When agents disagree:
1. Document the conflict in the relevant `plan.md` or ADR
2. Lead Architect makes the binding decision
3. Decision rationale MUST be recorded
4. Losing approach SHOULD be documented as "Alternative Rejected"

## Governance

### Constitution Authority

This constitution supersedes all other development practices. When in conflict:
1. Constitution principles take precedence
2. Amendments require documented justification and version increment
3. Emergency overrides MUST be temporary with follow-up amendment

### Amendment Process

1. Propose change with rationale in a PR or discussion
2. Impact assessment: which templates/code must change
3. Version increment following semver (MAJOR.MINOR.PATCH)
4. Update dependent artifacts (templates, CLAUDE.md if needed)
5. Document in Sync Impact Report

### Compliance Review

All PRs and code reviews MUST verify:
- [ ] Clean architecture boundaries maintained (Principle I)
- [ ] API contracts documented (Principle II)
- [ ] Data integrity constraints enforced (Principle III)
- [ ] CRUD operations complete and correct (Principle IV)
- [ ] Error handling follows standard structure (Principle V)
- [ ] UI meets Glassmorphism and accessibility standards (Principle VI)
- [ ] State management follows discipline (Principle VII)
- [ ] Production-ready checklist passes (Principle VIII)

### Complexity Justification

Adding complexity beyond what this constitution defines requires:
1. Written justification explaining why simpler approach is insufficient
2. Lead Architect approval
3. Documentation in ADR if architecturally significant

**Version**: 1.0.0 | **Ratified**: 2026-01-30 | **Last Amended**: 2026-01-30
