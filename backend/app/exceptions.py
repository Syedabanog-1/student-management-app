"""Custom exception handlers."""
from fastapi import Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError
from pydantic import ValidationError


async def integrity_error_handler(request: Request, exc: IntegrityError) -> JSONResponse:
    """Handle database integrity errors (duplicate entries)."""
    error_message = str(exc.orig).lower()

    if "email" in error_message:
        return JSONResponse(
            status_code=409,
            content={
                "detail": "A student with this email already exists",
                "code": "DUPLICATE_EMAIL",
                "field": "email"
            }
        )
    elif "roll_number" in error_message:
        return JSONResponse(
            status_code=409,
            content={
                "detail": "A student with this roll number already exists",
                "code": "DUPLICATE_ROLL_NUMBER",
                "field": "roll_number"
            }
        )
    else:
        return JSONResponse(
            status_code=409,
            content={
                "detail": "A duplicate entry was detected",
                "code": "DUPLICATE_ENTRY",
                "field": None
            }
        )


async def validation_error_handler(request: Request, exc: ValidationError) -> JSONResponse:
    """Handle pydantic validation errors."""
    errors = exc.errors()
    if errors:
        first_error = errors[0]
        field = first_error.get("loc", ["unknown"])[-1]
        message = first_error.get("msg", "Validation error")
        return JSONResponse(
            status_code=400,
            content={
                "detail": message,
                "code": "VALIDATION_ERROR",
                "field": str(field)
            }
        )
    return JSONResponse(
        status_code=400,
        content={
            "detail": "Validation error",
            "code": "VALIDATION_ERROR",
            "field": None
        }
    )


async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Handle all other exceptions."""
    return JSONResponse(
        status_code=500,
        content={
            "detail": "An internal server error occurred",
            "code": "INTERNAL_ERROR",
            "field": None
        }
    )
