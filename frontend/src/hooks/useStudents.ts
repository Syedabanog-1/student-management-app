"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  getStudents,
  createStudent,
  updateStudent,
  patchStudent,
  deleteStudent,
} from "@/services/api";
import type { StudentCreate, StudentUpdate, StudentPatch } from "@/types/student";

const STUDENTS_KEY = ["students"];

/**
 * Hook to fetch all students with optional search.
 */
export function useStudents(search?: string) {
  return useQuery({
    queryKey: [...STUDENTS_KEY, { search }],
    queryFn: () => getStudents(search),
    staleTime: 1000 * 30, // 30 seconds
  });
}

/**
 * Hook to create a new student.
 */
export function useCreateStudent() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: StudentCreate) => createStudent(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: STUDENTS_KEY });
    },
  });
}

/**
 * Hook to fully update a student (PUT).
 */
export function useUpdateStudent() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: StudentUpdate }) =>
      updateStudent(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: STUDENTS_KEY });
    },
  });
}

/**
 * Hook to partially update a student (PATCH).
 */
export function usePatchStudent() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: StudentPatch }) =>
      patchStudent(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: STUDENTS_KEY });
    },
  });
}

/**
 * Hook to delete a student.
 */
export function useDeleteStudent() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => deleteStudent(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: STUDENTS_KEY });
    },
  });
}
