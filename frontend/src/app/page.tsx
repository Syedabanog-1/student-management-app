"use client";

import { useState, useCallback } from "react";
import { ToastProvider, useToast } from "@/components/ui/Toast";
import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { SearchBar } from "@/components/SearchBar";
import { StudentForm } from "@/components/StudentForm";
import { DeleteConfirmDialog } from "@/components/DeleteConfirmDialog";
import {
  useStudents,
  useCreateStudent,
  useUpdateStudent,
  useDeleteStudent,
} from "@/hooks/useStudents";
import type { Student, StudentCreate } from "@/types/student";
import { ApiRequestError } from "@/services/api";

function StudentManagement() {
  const { showToast } = useToast();

  // Search state
  const [searchTerm, setSearchTerm] = useState("");

  // Modal states
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingStudent, setEditingStudent] = useState<Student | null>(null);
  const [deletingStudent, setDeletingStudent] = useState<Student | null>(null);

  // Toggle state for student list
  const [showStudentList, setShowStudentList] = useState(false);

  // Selected student for detail view
  const [selectedStudent, setSelectedStudent] = useState<Student | null>(null);

  // Form error state
  const [formError, setFormError] = useState<string>("");

  // Queries and mutations
  const { data: allStudents = [], isLoading: isLoadingAll } = useStudents(""); // All students
  const { data: students = [], isLoading, error } = useStudents(searchTerm); // Filtered students
  const createMutation = useCreateStudent();
  const updateMutation = useUpdateStudent();
  const deleteMutation = useDeleteStudent();

  // Handle add student
  const handleAddStudent = useCallback(
    async (data: StudentCreate) => {
      setFormError("");
      try {
        await createMutation.mutateAsync(data);
        setIsAddModalOpen(false);
        showToast("Student added successfully!", "success");
      } catch (err) {
        if (err instanceof ApiRequestError) {
          setFormError(err.message);
        } else {
          setFormError("Failed to add student. Please try again.");
        }
      }
    },
    [createMutation, showToast]
  );

  // Handle update student
  const handleUpdateStudent = useCallback(
    async (data: StudentCreate) => {
      if (!editingStudent) return;
      setFormError("");
      try {
        const updatedStudent = await updateMutation.mutateAsync({
          id: editingStudent.id,
          data,
        });
        // Update selected student if it was being edited
        if (selectedStudent?.id === editingStudent.id) {
          setSelectedStudent(updatedStudent);
        }
        setEditingStudent(null);
        showToast("Student updated successfully!", "success");
      } catch (err) {
        if (err instanceof ApiRequestError) {
          setFormError(err.message);
        } else {
          setFormError("Failed to update student. Please try again.");
        }
      }
    },
    [editingStudent, updateMutation, showToast, selectedStudent]
  );

  // Handle delete student
  const handleDeleteStudent = useCallback(async () => {
    if (!deletingStudent) return;
    try {
      await deleteMutation.mutateAsync(deletingStudent.id);
      // Close detail view if deleted student was selected
      if (selectedStudent?.id === deletingStudent.id) {
        setSelectedStudent(null);
      }
      setDeletingStudent(null);
      showToast("Student deleted successfully", "success");
    } catch (err) {
      if (err instanceof ApiRequestError) {
        showToast(err.message, "error");
      } else {
        showToast("Failed to delete student. Please try again.", "error");
      }
    }
  }, [deletingStudent, deleteMutation, showToast, selectedStudent]);

  // Handle edit click
  const handleEditClick = useCallback((student: Student) => {
    setFormError("");
    setEditingStudent(student);
  }, []);

  // Handle delete click
  const handleDeleteClick = useCallback((student: Student) => {
    setDeletingStudent(student);
  }, []);

  // Handle add new click
  const handleAddNewClick = useCallback(() => {
    setFormError("");
    setIsAddModalOpen(true);
  }, []);

  // Handle student select for detail view
  const handleStudentSelect = useCallback((student: Student) => {
    setSelectedStudent(student);
    setShowStudentList(false);
  }, []);

  // Close detail view
  const handleCloseDetail = useCallback(() => {
    setSelectedStudent(null);
  }, []);

  return (
    <main className="min-h-screen p-4 md:p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="animated-title-container">
            <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-2 animated-title">
              {"Student Management App".split("").map((letter, index) => (
                <span key={index} className="letter-animate">
                  {letter === " " ? "\u00A0" : letter}
                </span>
              ))}
            </h1>
          </div>
          <p className="text-white/70 text-lg">
            Manage your student records with ease
          </p>
        </div>

        {/* Actions Bar */}
        <div className="flex flex-col sm:flex-row gap-4 mb-8">
          <div className="flex-1">
            <SearchBar
              value={searchTerm}
              onChange={setSearchTerm}
              placeholder="Search by email or roll number..."
            />
          </div>
          <Button variant="primary" onClick={handleAddNewClick}>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 4v16m8-8H4"
              />
            </svg>
            Add Student
          </Button>
        </div>

        {/* Stats Bar */}
        <div className="glass-card p-4 mb-6 flex flex-wrap justify-center gap-6 text-white">
          <div className="flex items-center gap-2">
            <span className="text-white/70">Total Students:</span>
            <span className="bg-purple-500/50 px-3 py-1 rounded-full font-bold">{allStudents.length}</span>
          </div>
          {searchTerm && (
            <div className="flex items-center gap-2">
              <span className="text-white/70">Search Results:</span>
              <span className="bg-pink-500/50 px-3 py-1 rounded-full font-bold">{students.length}</span>
            </div>
          )}
        </div>

        {/* Student List Toggle Button */}
        <div className="flex justify-center mb-8">
          <button
            onClick={() => {
              setShowStudentList(!showStudentList);
              setSelectedStudent(null);
            }}
            className={`relative group px-6 py-4 text-lg font-semibold rounded-xl flex items-center gap-3 hover:scale-105 transition-all duration-300 ${
              showStudentList ? 'bg-purple-500/50 border-purple-300' : 'glass-button-primary'
            } border border-white/30`}
          >
            {!showStudentList && <span className="pulse-ring"></span>}
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
              />
            </svg>
            <span>Student List</span>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className={`h-5 w-5 transition-transform duration-300 ${showStudentList ? 'rotate-180' : ''}`}
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M19 9l-7 7-7-7"
              />
            </svg>
            <span className="absolute -top-2 -right-2 bg-purple-400 text-white text-sm font-bold px-2 py-1 rounded-full min-w-[24px]">
              {allStudents.length}
            </span>
          </button>
        </div>

        {/* Student List Section - Roll Numbers Only */}
        {showStudentList && !searchTerm && (
          <div className="glass-card p-6 mb-8 list-expand">
            <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              Student Roll Numbers
              <span className="text-sm font-normal text-white/70 ml-2">({allStudents.length} total)</span>
            </h2>
            <p className="text-white/60 text-sm mb-4">Click on any roll number to view student details</p>
            {isLoadingAll ? (
              <div className="animate-pulse space-y-2">
                {[...Array(5)].map((_, i) => (
                  <div key={i} className="h-10 bg-white/10 rounded"></div>
                ))}
              </div>
            ) : allStudents.length === 0 ? (
              <p className="text-white/70 text-center py-4">No students found</p>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
                {allStudents.map((student, index) => (
                  <div
                    key={student.id}
                    className={`card-slide-in card-delay-${Math.min(index + 1, 9)} flex items-center gap-3 bg-white/10 hover:bg-white/20 hover:scale-[1.02] p-3 rounded-lg transition-all duration-200 cursor-pointer border border-transparent hover:border-purple-400/50`}
                    onClick={() => handleStudentSelect(student)}
                  >
                    <span className="w-8 h-8 rounded-full bg-gradient-to-br from-purple-400 to-pink-400 flex items-center justify-center text-white font-bold text-sm">
                      {index + 1}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="font-mono text-white font-semibold truncate">{student.roll_number}</p>
                      <p className="text-white/60 text-xs truncate">{student.name}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Search Results - Show when searching */}
        {searchTerm && (
          <div className="mb-8 list-expand">
            <div className="glass-card p-4 mb-4">
              <div className="flex items-center justify-between flex-wrap gap-2">
                <p className="text-white">
                  Search Results for <span className="font-bold text-purple-300">&quot;{searchTerm}&quot;</span>
                </p>
                <span className="bg-pink-500/50 px-3 py-1 rounded-full font-bold text-white">
                  {students.length} found
                </span>
              </div>
            </div>
            {isLoading ? (
              <div className="glass-card p-6 animate-pulse">
                <div className="h-20 bg-white/10 rounded"></div>
              </div>
            ) : students.length === 0 ? (
              <div className="glass-card p-6 text-center">
                <svg xmlns="http://www.w3.org/2000/svg" className="h-12 w-12 mx-auto text-white/40 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <p className="text-white/70">No student found with this roll number or name</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {students.map((student, index) => (
                  <div
                    key={student.id}
                    className={`card-slide-in card-delay-${Math.min(index + 1, 9)} glass-card p-5 hover:scale-[1.02] transition-all duration-300 cursor-pointer`}
                    onClick={() => handleStudentSelect(student)}
                  >
                    <div className="flex items-center gap-4 mb-4">
                      <div className="w-14 h-14 rounded-full bg-gradient-to-br from-purple-400 to-pink-400 flex items-center justify-center text-white font-bold text-xl shadow-lg">
                        {student.name.charAt(0).toUpperCase()}
                      </div>
                      <div className="flex-1 min-w-0">
                        <h3 className="text-xl font-bold text-white truncate">{student.name}</h3>
                        <p className="text-purple-300 font-mono text-sm">{student.roll_number}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 text-white/70 text-sm">
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                      </svg>
                      <span className="truncate">{student.email}</span>
                    </div>
                    <p className="text-white/50 text-xs mt-3 text-center">Click to view full details</p>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Selected Student Detail View */}
        {selectedStudent && (
          <div className="mb-8 list-expand">
            <div className="glass-card p-6 max-w-2xl mx-auto">
              {/* Header with close button */}
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold text-white">Student Details</h2>
                <button
                  onClick={handleCloseDetail}
                  className="p-2 hover:bg-white/10 rounded-lg transition-colors"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-white/70 hover:text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              {/* Avatar and Name */}
              <div className="flex flex-col items-center mb-6">
                <div className="w-24 h-24 rounded-full bg-gradient-to-br from-purple-400 to-pink-400 flex items-center justify-center text-white font-bold text-4xl shadow-xl mb-4">
                  {selectedStudent.name.charAt(0).toUpperCase()}
                </div>
                <h3 className="text-3xl font-bold text-white text-center">{selectedStudent.name}</h3>
              </div>

              {/* Details */}
              <div className="space-y-4">
                <div className="bg-white/10 rounded-xl p-4 flex items-center gap-4">
                  <div className="w-12 h-12 rounded-full bg-purple-500/30 flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-purple-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" />
                    </svg>
                  </div>
                  <div>
                    <p className="text-white/60 text-sm">Roll Number</p>
                    <p className="text-white font-mono text-lg font-semibold">{selectedStudent.roll_number}</p>
                  </div>
                </div>

                <div className="bg-white/10 rounded-xl p-4 flex items-center gap-4">
                  <div className="w-12 h-12 rounded-full bg-pink-500/30 flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-pink-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <div>
                    <p className="text-white/60 text-sm">Email Address</p>
                    <p className="text-white text-lg">{selectedStudent.email}</p>
                  </div>
                </div>

                {selectedStudent.created_at && (
                  <div className="bg-white/10 rounded-xl p-4 flex items-center gap-4">
                    <div className="w-12 h-12 rounded-full bg-blue-500/30 flex items-center justify-center">
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-blue-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                    </div>
                    <div>
                      <p className="text-white/60 text-sm">Registered On</p>
                      <p className="text-white text-lg">{new Date(selectedStudent.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
                    </div>
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex gap-3 mt-6 pt-6 border-t border-white/20">
                <Button
                  variant="secondary"
                  onClick={() => {
                    handleEditClick(selectedStudent);
                  }}
                  className="flex-1"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                  Edit Student
                </Button>
                <Button
                  variant="danger"
                  onClick={() => {
                    handleDeleteClick(selectedStudent);
                  }}
                  className="flex-1"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                  Delete Student
                </Button>
              </div>
            </div>
          </div>
        )}

        {/* Add Student Modal */}
        <Modal
          isOpen={isAddModalOpen}
          onClose={() => setIsAddModalOpen(false)}
          title="Add New Student"
        >
          <StudentForm
            onSubmit={handleAddStudent}
            onCancel={() => setIsAddModalOpen(false)}
            isLoading={createMutation.isPending}
            error={formError}
          />
        </Modal>

        {/* Edit Student Modal */}
        <Modal
          isOpen={!!editingStudent}
          onClose={() => setEditingStudent(null)}
          title="Edit Student"
        >
          {editingStudent && (
            <StudentForm
              initialData={editingStudent}
              onSubmit={handleUpdateStudent}
              onCancel={() => setEditingStudent(null)}
              isLoading={updateMutation.isPending}
              error={formError}
            />
          )}
        </Modal>

        {/* Delete Confirmation Dialog */}
        <DeleteConfirmDialog
          student={deletingStudent}
          isOpen={!!deletingStudent}
          isLoading={deleteMutation.isPending}
          onConfirm={handleDeleteStudent}
          onCancel={() => setDeletingStudent(null)}
        />
      </div>
    </main>
  );
}

export default function Home() {
  return (
    <ToastProvider>
      <StudentManagement />
    </ToastProvider>
  );
}
