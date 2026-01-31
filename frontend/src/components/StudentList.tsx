"use client";

import { StudentCard } from "@/components/StudentCard";
import { GlassCard } from "@/components/ui/GlassCard";
import { Button } from "@/components/ui/Button";
import type { Student } from "@/types/student";

interface StudentListProps {
  students: Student[];
  isLoading: boolean;
  error?: Error | null;
  searchTerm?: string;
  onEdit: (student: Student) => void;
  onDelete: (student: Student) => void;
  onAddNew: () => void;
}

// Loading skeleton component
function LoadingSkeleton() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {[...Array(6)].map((_, i) => (
        <GlassCard key={i} className="animate-pulse">
          <div className="space-y-3">
            <div className="h-6 bg-white/20 rounded w-3/4" />
            <div className="h-4 bg-white/10 rounded w-full" />
            <div className="h-4 bg-white/10 rounded w-1/2" />
            <div className="flex gap-2 pt-3 border-t border-white/20">
              <div className="h-8 bg-white/10 rounded w-16" />
              <div className="h-8 bg-white/10 rounded w-16" />
            </div>
          </div>
        </GlassCard>
      ))}
    </div>
  );
}

// Empty state component
function EmptyState({ searchTerm, onAddNew }: { searchTerm?: string; onAddNew: () => void }) {
  if (searchTerm) {
    return (
      <GlassCard className="text-center py-12">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          className="h-16 w-16 mx-auto text-white/40 mb-4"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={1.5}
            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
          />
        </svg>
        <h3 className="text-xl font-semibold text-white mb-2">No students found</h3>
        <p className="text-white/70 mb-4">
          No students match &quot;{searchTerm}&quot;. Try adjusting your search or add a new student.
        </p>
        <Button variant="primary" onClick={onAddNew}>
          Add Student
        </Button>
      </GlassCard>
    );
  }

  return (
    <GlassCard className="text-center py-12">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        className="h-16 w-16 mx-auto text-white/40 mb-4"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={1.5}
          d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
        />
      </svg>
      <h3 className="text-xl font-semibold text-white mb-2">No students yet</h3>
      <p className="text-white/70 mb-4">
        Click &apos;Add Student&apos; to get started.
      </p>
      <Button variant="primary" onClick={onAddNew}>
        Add Student
      </Button>
    </GlassCard>
  );
}

// Error state component
function ErrorState({ error }: { error: Error }) {
  return (
    <GlassCard className="text-center py-12 border-red-400/30">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        className="h-16 w-16 mx-auto text-red-400 mb-4"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={1.5}
          d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
        />
      </svg>
      <h3 className="text-xl font-semibold text-white mb-2">Unable to load students</h3>
      <p className="text-white/70">{error.message || "Please try again later."}</p>
    </GlassCard>
  );
}

export function StudentList({
  students,
  isLoading,
  error,
  searchTerm,
  onEdit,
  onDelete,
  onAddNew,
}: StudentListProps) {
  if (isLoading) {
    return <LoadingSkeleton />;
  }

  if (error) {
    return <ErrorState error={error} />;
  }

  if (students.length === 0) {
    return <EmptyState searchTerm={searchTerm} onAddNew={onAddNew} />;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 list-expand">
      {students.map((student, index) => (
        <div
          key={student.id}
          className={`card-slide-in card-delay-${Math.min(index + 1, 9)}`}
        >
          <StudentCard
            student={student}
            onEdit={onEdit}
            onDelete={onDelete}
          />
        </div>
      ))}
    </div>
  );
}
