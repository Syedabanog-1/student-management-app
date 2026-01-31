# Student Management - Frontend

Next.js 14 frontend for the Student Management application with Glassmorphism UI.

## Setup

### Prerequisites
- Node.js 20+
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env.local
```

### Running the Development Server

```bash
npm run dev
```

Frontend will be available at http://localhost:3000

## Project Structure

```
frontend/
├── src/
│   ├── app/
│   │   ├── layout.tsx     # Root layout with providers
│   │   ├── page.tsx       # Main student management page
│   │   └── globals.css    # Global styles + Glassmorphism
│   ├── components/
│   │   ├── ui/            # Base UI components
│   │   │   ├── Button.tsx
│   │   │   ├── GlassCard.tsx
│   │   │   ├── Input.tsx
│   │   │   ├── Modal.tsx
│   │   │   └── Toast.tsx
│   │   ├── StudentCard.tsx
│   │   ├── StudentForm.tsx
│   │   ├── StudentList.tsx
│   │   ├── SearchBar.tsx
│   │   └── DeleteConfirmDialog.tsx
│   ├── hooks/
│   │   └── useStudents.ts  # React Query hooks
│   ├── services/
│   │   └── api.ts          # API client
│   └── types/
│       └── student.ts      # TypeScript types
├── tailwind.config.ts
├── tsconfig.json
├── next.config.js
└── package.json
```

## Features

- Glassmorphism UI design with glass-effect cards
- Real-time search with debouncing
- Full CRUD operations
- Form validation (client-side)
- Toast notifications
- Responsive layout (mobile-first)
- Loading skeletons
- Error states
- Empty states

## Components

### UI Components
- `GlassCard` - Glass-effect container
- `Button` - Primary/secondary/danger variants with loading state
- `Input` - Form input with label and error display
- `Modal` - Overlay dialog with animation
- `Toast` - Auto-dismiss notifications

### Feature Components
- `SearchBar` - Debounced search input
- `StudentForm` - Add/Edit form with validation
- `StudentCard` - Student display card with actions
- `StudentList` - Grid layout with loading/empty/error states
- `DeleteConfirmDialog` - Confirmation modal

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| NEXT_PUBLIC_API_URL | Backend API URL | `http://localhost:8000/api` |

## Building for Production

```bash
npm run build
npm start
```
