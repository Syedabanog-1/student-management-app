"""Model exports."""
from app.models.student import (
    Student,
    StudentBase,
    StudentCreate,
    StudentUpdate,
    StudentPatch,
    StudentRead,
)

__all__ = [
    "Student",
    "StudentBase",
    "StudentCreate",
    "StudentUpdate",
    "StudentPatch",
    "StudentRead",
]
