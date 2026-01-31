# Student Management Application

A full-stack web application for managing student records with a modern Glassmorphism UI design.

## Features

- Add, view, search, update, and delete student records
- Unique email and roll number validation
- Real-time search filtering
- Modern glass-effect UI with responsive design
- RESTful API with proper error handling

## Tech Stack

### Backend
- **FastAPI** - Modern Python web framework
- **SQLModel** - SQL databases with Python types
- **SQLite** - Lightweight database
- **Pydantic** - Data validation

### Frontend
- **Next.js 14** - React framework with App Router
- **TypeScript** - Type-safe JavaScript
- **Tailwind CSS** - Utility-first CSS
- **React Query** - Server state management

## Quick Start

### Prerequisites
- Python 3.11+
- Node.js 20+
- npm or yarn

### Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload
```

Backend will be running at http://localhost:8000

### Frontend Setup

```bash
cd frontend
npm install
cp .env.example .env.local
npm run dev
```

Frontend will be running at http://localhost:3000

### Using Docker Compose

```bash
docker-compose up --build
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/students | List all students (with optional search) |
| GET | /api/students/{id} | Get a student by ID |
| POST | /api/students | Create a new student |
| PUT | /api/students/{id} | Full update of a student |
| PATCH | /api/students/{id} | Partial update of a student |
| DELETE | /api/students/{id} | Delete a student |
| GET | /api/health | Health check endpoint |

## Project Structure

```
student-management-app/
├── backend/
│   ├── app/
│   │   ├── api/          # API routes
│   │   ├── models/       # SQLModel models
│   │   ├── main.py       # FastAPI app
│   │   └── database.py   # Database config
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── app/          # Next.js pages
│   │   ├── components/   # React components
│   │   ├── hooks/        # Custom hooks
│   │   ├── services/     # API services
│   │   └── types/        # TypeScript types
│   └── package.json
└── docker-compose.yml
```

## Documentation

See `specs/001-student-crud-app/` for detailed documentation:
- `spec.md` - Feature specification
- `plan.md` - Implementation plan
- `quickstart.md` - Detailed setup instructions
- `contracts/students-api.yaml` - OpenAPI specification
