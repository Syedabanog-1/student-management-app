# Data Model: Student Management CRUD Application

**Feature**: 001-student-crud-app
**Date**: 2026-01-30
**Status**: Complete

## Entity: Student

### Definition

A Student represents an enrolled individual in the educational institution's registry.

### Fields

| Field | Type | Required | Unique | Default | Description |
|-------|------|----------|--------|---------|-------------|
| id | Integer | Auto | Yes | Auto-increment | Primary key, system-generated |
| name | String(100) | Yes | No | - | Full name of the student |
| email | String(255) | Yes | Yes | - | Contact email address |
| roll_number | String(50) | Yes | Yes | - | Institutional identifier |
| created_at | DateTime | Auto | No | Current timestamp | Record creation time |
| updated_at | DateTime | Auto | No | Current timestamp | Last modification time |

### Validation Rules

#### Name
- **Required**: Cannot be empty or null
- **Length**: 1-100 characters
- **Format**: Any Unicode characters allowed (supports international names)
- **Trimming**: Leading/trailing whitespace should be trimmed

#### Email
- **Required**: Cannot be empty or null
- **Format**: Must match standard email pattern (RFC 5322 simplified)
- **Uniqueness**: Database-level unique constraint
- **Case**: Stored as-is, but uniqueness check is case-insensitive

#### Roll Number
- **Required**: Cannot be empty or null
- **Length**: 1-50 characters
- **Format**: Alphanumeric (letters, numbers, hyphens allowed)
- **Uniqueness**: Database-level unique constraint
- **Case**: Stored as-is, uniqueness check is case-sensitive

### Model Definitions

#### Student (Database Model)

```python
# backend/app/models/student.py
from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field
from pydantic import EmailStr, field_validator
import re

class StudentBase(SQLModel):
    """Base model with shared fields"""
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr = Field(max_length=255)
    roll_number: str = Field(min_length=1, max_length=50)

    @field_validator('name')
    @classmethod
    def trim_name(cls, v: str) -> str:
        return v.strip()

    @field_validator('roll_number')
    @classmethod
    def validate_roll_number(cls, v: str) -> str:
        if not re.match(r'^[A-Za-z0-9-]+$', v):
            raise ValueError('Roll number must be alphanumeric (letters, numbers, hyphens only)')
        return v

class Student(StudentBase, table=True):
    """Database table model"""
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class StudentCreate(StudentBase):
    """Model for creating a new student"""
    pass

class StudentUpdate(SQLModel):
    """Model for full update (PUT) - all fields required"""
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr = Field(max_length=255)
    roll_number: str = Field(min_length=1, max_length=50)

class StudentPatch(SQLModel):
    """Model for partial update (PATCH) - all fields optional"""
    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    email: Optional[EmailStr] = Field(default=None, max_length=255)
    roll_number: Optional[str] = Field(default=None, min_length=1, max_length=50)

class StudentRead(StudentBase):
    """Model for API responses"""
    id: int
    created_at: datetime
    updated_at: datetime
```

### TypeScript Types (Frontend)

```typescript
// frontend/src/types/student.ts

export interface Student {
  id: number;
  name: string;
  email: string;
  roll_number: string;
  created_at: string;  // ISO 8601 datetime
  updated_at: string;  // ISO 8601 datetime
}

export interface StudentCreate {
  name: string;
  email: string;
  roll_number: string;
}

export interface StudentUpdate {
  name: string;
  email: string;
  roll_number: string;
}

export interface StudentPatch {
  name?: string;
  email?: string;
  roll_number?: string;
}

export interface StudentListResponse {
  students: Student[];
  total: number;
}

export interface ApiError {
  detail: string;
  code: string;
  field?: string;
}
```

### Database Schema (SQLite)

```sql
CREATE TABLE student (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    roll_number VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_student_email ON student(email);
CREATE INDEX idx_student_roll_number ON student(roll_number);
CREATE INDEX idx_student_name ON student(name);
```

### State Transitions

The Student entity is simple with no complex state machine. Records can be:
1. **Created** (POST) - New record with all required fields
2. **Read** (GET) - Retrieved by ID or listed with optional search
3. **Updated** (PUT/PATCH) - Modified with new values
4. **Deleted** (DELETE) - Permanently removed

### Relationships

For MVP, the Student entity has no relationships to other entities. Future extensions might include:
- Courses (many-to-many)
- Departments (many-to-one)
- Enrollments (one-to-many)

These are explicitly out of scope for this feature.
