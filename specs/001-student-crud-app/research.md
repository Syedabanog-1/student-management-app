# Research: Student Management CRUD Application

**Feature**: 001-student-crud-app
**Date**: 2026-01-30
**Status**: Complete

## Technology Decisions

### Backend Framework: FastAPI

**Decision**: Use FastAPI 0.109+ as the backend framework

**Rationale**:
- Native async support for high-performance APIs
- Automatic OpenAPI documentation generation
- Built-in Pydantic validation (integrates seamlessly with SQLModel)
- Excellent developer experience with type hints
- Constitution mandates API-first development - FastAPI generates OpenAPI specs automatically

**Alternatives Considered**:
- Flask: Simpler but lacks async and automatic validation
- Django REST Framework: Heavier, better for larger applications with admin needs
- Express.js: Would require maintaining two languages (Node + Python)

### ORM: SQLModel

**Decision**: Use SQLModel 0.0.14+ for database models

**Rationale**:
- Combines SQLAlchemy ORM with Pydantic validation in single model definitions
- Reduces code duplication between database models and API schemas
- Native integration with FastAPI
- Supports unique constraints directly in model definition
- Constitution requires data integrity at model level - SQLModel validators enforce this

**Alternatives Considered**:
- SQLAlchemy alone: Would require separate Pydantic schemas
- Tortoise ORM: Less mature, smaller community
- Prisma: Better suited for Node.js projects

### Database: SQLite

**Decision**: Use SQLite for data persistence

**Rationale**:
- Zero configuration - no external database server needed
- File-based storage perfect for single-user admin application
- Sufficient performance for <10k records
- Easy to backup (single file)
- Simplifies development and deployment

**Alternatives Considered**:
- PostgreSQL: Overkill for single-user app, adds deployment complexity
- MySQL: Same concerns as PostgreSQL
- In-memory only: Data would be lost on restart

### Frontend Framework: Next.js 14+

**Decision**: Use Next.js 14+ with App Router

**Rationale**:
- React-based with excellent TypeScript support
- App Router provides modern file-based routing
- Server Components available but not required for this SPA use case
- Strong community and ecosystem
- Constitution requires modern UI standards - Next.js enables this

**Alternatives Considered**:
- Vite + React: Would work but loses SSR capabilities if needed later
- Create React App: Deprecated, not recommended for new projects
- Remix: Good but less ecosystem support for Glassmorphism component libraries

### State Management: React Query (TanStack Query)

**Decision**: Use TanStack Query v5 for server state management

**Rationale**:
- Purpose-built for server state caching and synchronization
- Automatic refetching, cache invalidation, optimistic updates
- Reduces boilerplate compared to Redux or Context for API data
- Constitution Principle VII mandates React Query or SWR

**Alternatives Considered**:
- SWR: Simpler but less feature-rich for mutations
- Redux Toolkit Query: More complex setup, better for larger apps
- Zustand: Good for client state, not designed for server state

### Styling: Tailwind CSS + Custom Glassmorphism

**Decision**: Use Tailwind CSS 3.4+ with custom CSS for Glassmorphism effects

**Rationale**:
- Utility-first approach enables rapid UI development
- Excellent responsive design utilities
- Custom CSS required for `backdrop-filter` and glass effects
- Constitution Principle VI mandates Glassmorphism design

**Implementation Notes**:
```css
/* Glassmorphism base utilities */
.glass {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 16px;
}
```

**Alternatives Considered**:
- CSS Modules: Less utility support, more verbose
- Styled Components: Runtime overhead, less performant
- Plain CSS: Would work but slower development

## API Design Decisions

### REST vs GraphQL

**Decision**: Use RESTful API design

**Rationale**:
- Simple CRUD operations don't require GraphQL's flexibility
- FastAPI provides excellent REST support with automatic docs
- Easier to cache and debug
- Constitution Principle IV defines specific REST endpoints

### Error Response Format

**Decision**: Standardized JSON error structure

```json
{
  "detail": "Human-readable error message",
  "code": "ERROR_CODE",
  "field": "optional_field_name"
}
```

**Rationale**:
- Constitution Principle V mandates this exact format
- Enables frontend to display field-level errors
- `code` allows programmatic error handling
- Consistent across all error types

### HTTP Status Codes

| Scenario | Status Code |
|----------|-------------|
| Validation error | 400 Bad Request |
| Not found | 404 Not Found |
| Duplicate email/roll_number | 409 Conflict |
| Server error | 500 Internal Server Error |
| Success (create) | 201 Created |
| Success (update/delete) | 200 OK |
| Success (list/get) | 200 OK |

## Security Considerations

### CORS Configuration

**Decision**: Allow frontend origin only in development, configurable for production

```python
# Development
origins = ["http://localhost:3000"]

# Production (via environment variable)
origins = os.getenv("ALLOWED_ORIGINS", "").split(",")
```

### Input Validation

**Decision**: Validate at multiple layers

1. **Pydantic/SQLModel**: Type validation, email format, string length
2. **Database**: Unique constraints as final safeguard
3. **Frontend**: Client-side validation for UX (server remains authoritative)

### No Authentication

**Decision**: No authentication for MVP

**Rationale**: Per spec assumptions, single administrator role. Authentication can be added as a future feature if multi-user access is needed.

## Performance Considerations

### Search Implementation

**Decision**: Case-insensitive LIKE queries with SQLite

```python
# Backend search implementation
query = select(Student).where(
    or_(
        Student.name.ilike(f"%{search}%"),
        Student.email.ilike(f"%{search}%"),
        Student.roll_number.ilike(f"%{search}%")
    )
)
```

**Rationale**: SQLite LIKE is efficient for <10k records. Index on searchable fields if performance becomes an issue.

### Frontend Caching

**Decision**: React Query with 30-second stale time

```typescript
// Default query configuration
{
  staleTime: 30 * 1000,      // 30 seconds
  gcTime: 5 * 60 * 1000,     // 5 minutes
  refetchOnWindowFocus: true
}
```

## Open Questions Resolved

All technical questions have been resolved. No blockers for implementation.
