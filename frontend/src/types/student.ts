/**
 * Student type definitions matching the backend API.
 */

export interface Student {
  id: number;
  name: string;
  email: string;
  roll_number: string;
  created_at: string; // ISO 8601 datetime
  updated_at: string; // ISO 8601 datetime
}

export interface StudentCreate {
  name: string;
  email: string;
  roll_number: string;
}

export interface StudentUpdate {
  name: string;
  email: string;
  roll_number: string;
}

export interface StudentPatch {
  name?: string;
  email?: string;
  roll_number?: string;
}

export interface ApiError {
  detail: string;
  code: string;
  field?: string;
}

export interface DeleteResponse {
  message: string;
}
