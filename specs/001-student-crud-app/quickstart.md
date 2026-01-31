# Quickstart: Student Management CRUD Application

**Feature**: 001-student-crud-app
**Date**: 2026-01-30

## Prerequisites

- **Python**: 3.11 or higher
- **Node.js**: 20 or higher
- **npm**: 10 or higher (comes with Node.js)
- **Git**: For version control

## Quick Setup (5 minutes)

### Option 1: Using Docker Compose (Recommended)

```bash
# Clone and navigate to project
cd student-management-app

# Start all services
docker-compose up -d

# Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

### Option 2: Manual Setup

#### Step 1: Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env

# Start the server
uvicorn app.main:app --reload --port 8000
```

The backend will be available at `http://localhost:8000`

#### Step 2: Frontend Setup

```bash
# Open new terminal, navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env.local

# Start development server
npm run dev
```

The frontend will be available at `http://localhost:3000`

## Verify Installation

### Backend Health Check

```bash
curl http://localhost:8000/api/health
```

Expected response:
```json
{"status": "healthy", "timestamp": "2026-01-30T12:00:00.000Z"}
```

### API Documentation

Open `http://localhost:8000/docs` in your browser to see the interactive API documentation (Swagger UI).

### Frontend

Open `http://localhost:3000` in your browser. You should see the Student Management dashboard with:
- Search bar at the top
- "Add Student" button
- Empty state message (no students yet)

## Test the Application

### 1. Add a Student

1. Click "Add Student" button
2. Fill in the form:
   - Name: `John Doe`
   - Email: `john.doe@example.com`
   - Roll Number: `CS-2024-001`
3. Click "Save"
4. See success notification and student appears in list

### 2. Search Students

1. Type "john" in the search bar
2. List filters to show matching students
3. Clear search to see all students

### 3. Edit a Student

1. Click on a student card
2. Click "Edit" button
3. Modify any field
4. Click "Save"
5. See updated information

### 4. Delete a Student

1. Click on a student card
2. Click "Delete" button
3. Confirm in the dialog
4. Student is removed from list

## API Examples

### Create Student

```bash
curl -X POST http://localhost:8000/api/students \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Smith",
    "email": "jane.smith@example.com",
    "roll_number": "CS-2024-002"
  }'
```

### List Students with Search

```bash
curl "http://localhost:8000/api/students?search=jane"
```

### Update Student (Full)

```bash
curl -X PUT http://localhost:8000/api/students/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Doe",
    "email": "jane.doe@example.com",
    "roll_number": "CS-2024-002"
  }'
```

### Update Student (Partial)

```bash
curl -X PATCH http://localhost:8000/api/students/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Doe-Smith"
  }'
```

### Delete Student

```bash
curl -X DELETE http://localhost:8000/api/students/1
```

## Environment Variables

### Backend (`backend/.env`)

```env
# Database
DATABASE_URL=sqlite:///./students.db

# CORS
ALLOWED_ORIGINS=http://localhost:3000

# Environment
ENVIRONMENT=development
```

### Frontend (`frontend/.env.local`)

```env
# API URL
NEXT_PUBLIC_API_URL=http://localhost:8000/api
```

## Troubleshooting

### "CORS error" in browser console

Ensure the backend is running and CORS is configured correctly:
```python
# backend/app/main.py should have:
origins = ["http://localhost:3000"]
app.add_middleware(CORSMiddleware, allow_origins=origins, ...)
```

### "Module not found" in Python

Ensure virtual environment is activated:
```bash
# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

### "Cannot connect to API" in frontend

1. Check backend is running: `curl http://localhost:8000/api/health`
2. Verify `NEXT_PUBLIC_API_URL` in `.env.local`
3. Restart the frontend: `npm run dev`

### Database errors

Reset the database:
```bash
cd backend
rm students.db
# Restart the server - tables will be recreated
uvicorn app.main:app --reload
```

## Development Commands

### Backend

```bash
# Run tests
pytest

# Run with auto-reload
uvicorn app.main:app --reload

# Check code formatting
black --check app/

# Type checking
mypy app/
```

### Frontend

```bash
# Run tests
npm test

# Build for production
npm run build

# Check linting
npm run lint

# Type checking
npm run type-check
```

## Next Steps

1. Review the [API Contract](./contracts/students-api.yaml) for full endpoint documentation
2. Check [Data Model](./data-model.md) for entity definitions
3. See [Implementation Plan](./plan.md) for development phases
