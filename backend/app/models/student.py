"""Student model definitions."""
from datetime import datetime, timezone
from typing import Optional
import re

from pydantic import EmailStr, field_validator
from sqlmodel import SQLModel, Field


class StudentBase(SQLModel):
    """Base model with shared fields."""

    name: str = Field(min_length=1, max_length=100, description="Full name of the student")
    email: EmailStr = Field(max_length=255, description="Contact email address")
    roll_number: str = Field(min_length=1, max_length=50, description="Institutional identifier")

    @field_validator("name")
    @classmethod
    def trim_name(cls, v: str) -> str:
        """Trim whitespace from name."""
        return v.strip()

    @field_validator("roll_number")
    @classmethod
    def validate_roll_number(cls, v: str) -> str:
        """Validate roll number is alphanumeric with hyphens."""
        if not re.match(r"^[A-Za-z0-9-]+$", v):
            raise ValueError("Roll number must be alphanumeric (letters, numbers, hyphens only)")
        return v


class Student(StudentBase, table=True):
    """Database table model."""

    id: Optional[int] = Field(default=None, primary_key=True)
    email: EmailStr = Field(max_length=255, unique=True, index=True)
    roll_number: str = Field(min_length=1, max_length=50, unique=True, index=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class StudentCreate(StudentBase):
    """Model for creating a new student."""
    pass


class StudentUpdate(SQLModel):
    """Model for full update (PUT) - all fields required."""

    name: str = Field(min_length=1, max_length=100)
    email: EmailStr = Field(max_length=255)
    roll_number: str = Field(min_length=1, max_length=50)

    @field_validator("name")
    @classmethod
    def trim_name(cls, v: str) -> str:
        """Trim whitespace from name."""
        return v.strip()

    @field_validator("roll_number")
    @classmethod
    def validate_roll_number(cls, v: str) -> str:
        """Validate roll number is alphanumeric with hyphens."""
        if not re.match(r"^[A-Za-z0-9-]+$", v):
            raise ValueError("Roll number must be alphanumeric (letters, numbers, hyphens only)")
        return v


class StudentPatch(SQLModel):
    """Model for partial update (PATCH) - all fields optional."""

    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    email: Optional[EmailStr] = Field(default=None, max_length=255)
    roll_number: Optional[str] = Field(default=None, min_length=1, max_length=50)

    @field_validator("name")
    @classmethod
    def trim_name(cls, v: Optional[str]) -> Optional[str]:
        """Trim whitespace from name if provided."""
        return v.strip() if v else v

    @field_validator("roll_number")
    @classmethod
    def validate_roll_number(cls, v: Optional[str]) -> Optional[str]:
        """Validate roll number is alphanumeric with hyphens if provided."""
        if v and not re.match(r"^[A-Za-z0-9-]+$", v):
            raise ValueError("Roll number must be alphanumeric (letters, numbers, hyphens only)")
        return v


class StudentRead(StudentBase):
    """Model for API responses."""

    id: int
    created_at: datetime
    updated_at: datetime
