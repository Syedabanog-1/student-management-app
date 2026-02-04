/**
 * API service for student management.
 */
import type { Student, StudentCreate, StudentUpdate, StudentPatch, ApiError, DeleteResponse } from "@/types/student";

// Use relative path to leverage Next.js proxy (configured in next.config.js)
// This avoids CORS issues when calling the backend API
const API_BASE_URL = "/api";

/**
 * Custom error class for API errors.
 */
export class ApiRequestError extends Error {
  constructor(
    message: string,
    public code: string,
    public field?: string,
    public status?: number
  ) {
    super(message);
    this.name = "ApiRequestError";
  }
}

/**
 * Base fetch wrapper with error handling.
 */
async function fetchApi<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;

  const response = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
  });

  if (!response.ok) {
    let errorData: ApiError;
    try {
      const jsonResponse = await response.json();
      // FastAPI wraps HTTPException detail in a "detail" key
      // Handle both nested format {"detail": {"detail": "...", "code": "..."}}
      // and flat format {"detail": "...", "code": "..."}
      if (jsonResponse.detail && typeof jsonResponse.detail === "object") {
        errorData = jsonResponse.detail as ApiError;
      } else if (jsonResponse.detail && typeof jsonResponse.detail === "string") {
        errorData = {
          detail: jsonResponse.detail,
          code: "VALIDATION_ERROR",
        };
      } else {
        errorData = jsonResponse as ApiError;
      }
    } catch {
      errorData = {
        detail: "An unexpected error occurred",
        code: "UNKNOWN_ERROR",
      };
    }
    throw new ApiRequestError(
      errorData.detail,
      errorData.code,
      errorData.field,
      response.status
    );
  }

  return response.json();
}

/**
 * Get all students with optional search.
 */
export async function getStudents(search?: string): Promise<Student[]> {
  const params = search ? `?search=${encodeURIComponent(search)}` : "";
  return fetchApi<Student[]>(`/students${params}`);
}

/**
 * Get a single student by ID.
 */
export async function getStudent(id: number): Promise<Student> {
  return fetchApi<Student>(`/students/${id}`);
}

/**
 * Create a new student.
 */
export async function createStudent(data: StudentCreate): Promise<Student> {
  return fetchApi<Student>("/students", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

/**
 * Full update of a student (PUT).
 */
export async function updateStudent(id: number, data: StudentUpdate): Promise<Student> {
  return fetchApi<Student>(`/students/${id}`, {
    method: "PUT",
    body: JSON.stringify(data),
  });
}

/**
 * Partial update of a student (PATCH).
 */
export async function patchStudent(id: number, data: StudentPatch): Promise<Student> {
  return fetchApi<Student>(`/students/${id}`, {
    method: "PATCH",
    body: JSON.stringify(data),
  });
}

/**
 * Delete a student.
 */
export async function deleteStudent(id: number): Promise<DeleteResponse> {
  return fetchApi<DeleteResponse>(`/students/${id}`, {
    method: "DELETE",
  });
}
