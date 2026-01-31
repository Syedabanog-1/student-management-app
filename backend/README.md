# Student Management API - Backend

FastAPI backend for the Student Management application.

## Setup

### Prerequisites
- Python 3.11+
- pip

### Installation

```bash
# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (Linux/Mac)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
```

### Running the Server

```bash
uvicorn app.main:app --reload
```

Server will be available at http://localhost:8000

### API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/students | List students (optional `?search=` param) |
| GET | /api/students/{id} | Get student by ID |
| POST | /api/students | Create new student |
| PUT | /api/students/{id} | Full update |
| PATCH | /api/students/{id} | Partial update |
| DELETE | /api/students/{id} | Delete student |
| GET | /api/health | Health check |

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py          # FastAPI app entry point
│   ├── config.py        # Settings management
│   ├── database.py      # SQLite + SQLModel setup
│   ├── exceptions.py    # Custom error handlers
│   ├── api/
│   │   └── students.py  # CRUD endpoints
│   └── models/
│       └── student.py   # Pydantic/SQLModel models
├── tests/
│   ├── conftest.py
│   └── test_students_api.py
├── requirements.txt
└── .env.example
```

## Testing

```bash
pytest
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| DATABASE_URL | SQLite connection string | `sqlite:///./students.db` |
| ALLOWED_ORIGINS | CORS origins (comma-separated) | `http://localhost:3000` |
