"""Student CRUD API endpoints."""
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select, or_

from app.database import get_session
from app.models import Student, StudentCreate, StudentUpdate, StudentPatch, StudentRead

router = APIRouter(prefix="/students", tags=["Students"])


@router.get("", response_model=list[StudentRead])
def list_students(
    search: Optional[str] = Query(None, description="Search term for name, email, or roll_number"),
    session: Session = Depends(get_session)
) -> list[Student]:
    """List all students with optional search filter."""
    statement = select(Student)

    if search:
        search_term = f"%{search}%"
        statement = statement.where(
            or_(
                Student.name.ilike(search_term),
                Student.email.ilike(search_term),
                Student.roll_number.ilike(search_term)
            )
        )

    students = session.exec(statement).all()
    return list(students)


@router.get("/{student_id}", response_model=StudentRead)
def get_student(
    student_id: int,
    session: Session = Depends(get_session)
) -> Student:
    """Get a single student by ID."""
    student = session.get(Student, student_id)
    if not student:
        raise HTTPException(
            status_code=404,
            detail={
                "detail": "Student not found",
                "code": "NOT_FOUND",
                "field": "id"
            }
        )
    return student


@router.post("", response_model=StudentRead, status_code=201)
def create_student(
    student_data: StudentCreate,
    session: Session = Depends(get_session)
) -> Student:
    """Create a new student."""
    # Check for duplicate email
    existing_email = session.exec(
        select(Student).where(Student.email == student_data.email)
    ).first()
    if existing_email:
        raise HTTPException(
            status_code=409,
            detail={
                "detail": "A student with this email already exists",
                "code": "DUPLICATE_EMAIL",
                "field": "email"
            }
        )

    # Check for duplicate roll_number
    existing_roll = session.exec(
        select(Student).where(Student.roll_number == student_data.roll_number)
    ).first()
    if existing_roll:
        raise HTTPException(
            status_code=409,
            detail={
                "detail": "A student with this roll number already exists",
                "code": "DUPLICATE_ROLL_NUMBER",
                "field": "roll_number"
            }
        )

    student = Student.model_validate(student_data)
    session.add(student)
    session.commit()
    session.refresh(student)
    return student


@router.put("/{student_id}", response_model=StudentRead)
def update_student(
    student_id: int,
    student_data: StudentUpdate,
    session: Session = Depends(get_session)
) -> Student:
    """Full update of a student (all fields required)."""
    student = session.get(Student, student_id)
    if not student:
        raise HTTPException(
            status_code=404,
            detail={
                "detail": "Student not found",
                "code": "NOT_FOUND",
                "field": "id"
            }
        )

    # Check for duplicate email (exclude current student)
    existing_email = session.exec(
        select(Student).where(
            Student.email == student_data.email,
            Student.id != student_id
        )
    ).first()
    if existing_email:
        raise HTTPException(
            status_code=409,
            detail={
                "detail": "A student with this email already exists",
                "code": "DUPLICATE_EMAIL",
                "field": "email"
            }
        )

    # Check for duplicate roll_number (exclude current student)
    existing_roll = session.exec(
        select(Student).where(
            Student.roll_number == student_data.roll_number,
            Student.id != student_id
        )
    ).first()
    if existing_roll:
        raise HTTPException(
            status_code=409,
            detail={
                "detail": "A student with this roll number already exists",
                "code": "DUPLICATE_ROLL_NUMBER",
                "field": "roll_number"
            }
        )

    # Update all fields
    student.name = student_data.name
    student.email = student_data.email
    student.roll_number = student_data.roll_number
    student.updated_at = datetime.utcnow()

    session.add(student)
    session.commit()
    session.refresh(student)
    return student


@router.patch("/{student_id}", response_model=StudentRead)
def patch_student(
    student_id: int,
    student_data: StudentPatch,
    session: Session = Depends(get_session)
) -> Student:
    """Partial update of a student (only provided fields are updated)."""
    student = session.get(Student, student_id)
    if not student:
        raise HTTPException(
            status_code=404,
            detail={
                "detail": "Student not found",
                "code": "NOT_FOUND",
                "field": "id"
            }
        )

    # Update only provided fields using exclude_unset
    update_data = student_data.model_dump(exclude_unset=True)

    # Check for duplicate email if email is being updated
    if "email" in update_data:
        existing_email = session.exec(
            select(Student).where(
                Student.email == update_data["email"],
                Student.id != student_id
            )
        ).first()
        if existing_email:
            raise HTTPException(
                status_code=409,
                detail={
                    "detail": "A student with this email already exists",
                    "code": "DUPLICATE_EMAIL",
                    "field": "email"
                }
            )

    # Check for duplicate roll_number if roll_number is being updated
    if "roll_number" in update_data:
        existing_roll = session.exec(
            select(Student).where(
                Student.roll_number == update_data["roll_number"],
                Student.id != student_id
            )
        ).first()
        if existing_roll:
            raise HTTPException(
                status_code=409,
                detail={
                    "detail": "A student with this roll number already exists",
                    "code": "DUPLICATE_ROLL_NUMBER",
                    "field": "roll_number"
                }
            )

    for key, value in update_data.items():
        setattr(student, key, value)

    student.updated_at = datetime.utcnow()

    session.add(student)
    session.commit()
    session.refresh(student)
    return student


@router.delete("/{student_id}")
def delete_student(
    student_id: int,
    session: Session = Depends(get_session)
) -> dict:
    """Delete a student."""
    student = session.get(Student, student_id)
    if not student:
        raise HTTPException(
            status_code=404,
            detail={
                "detail": "Student not found",
                "code": "NOT_FOUND",
                "field": "id"
            }
        )

    session.delete(student)
    session.commit()
    return {"message": "Student deleted successfully"}
