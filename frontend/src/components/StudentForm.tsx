"use client";

import { useState, useEffect, FormEvent } from "react";
import { Input } from "@/components/ui/Input";
import { Button } from "@/components/ui/Button";
import type { Student, StudentCreate } from "@/types/student";

interface StudentFormProps {
  initialData?: Student;
  onSubmit: (data: StudentCreate) => void;
  onCancel: () => void;
  isLoading?: boolean;
  error?: string;
}

interface FormErrors {
  name?: string;
  email?: string;
  roll_number?: string;
}

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const ROLL_NUMBER_REGEX = /^[A-Za-z0-9-]+$/;

export function StudentForm({
  initialData,
  onSubmit,
  onCancel,
  isLoading = false,
  error,
}: StudentFormProps) {
  const [name, setName] = useState(initialData?.name || "");
  const [email, setEmail] = useState(initialData?.email || "");
  const [rollNumber, setRollNumber] = useState(initialData?.roll_number || "");
  const [errors, setErrors] = useState<FormErrors>({});
  const [touched, setTouched] = useState<Record<string, boolean>>({});

  const isEditMode = !!initialData;

  // Reset form when initialData changes
  useEffect(() => {
    if (initialData) {
      setName(initialData.name);
      setEmail(initialData.email);
      setRollNumber(initialData.roll_number);
    }
  }, [initialData]);

  const validateField = (field: string, value: string): string | undefined => {
    switch (field) {
      case "name":
        if (!value.trim()) return "Name is required";
        if (value.trim().length > 100) return "Name must be 100 characters or less";
        return undefined;
      case "email":
        if (!value.trim()) return "Email is required";
        if (!EMAIL_REGEX.test(value)) return "Please enter a valid email address";
        return undefined;
      case "roll_number":
        if (!value.trim()) return "Roll number is required";
        if (!ROLL_NUMBER_REGEX.test(value))
          return "Roll number must be alphanumeric (letters, numbers, hyphens only)";
        if (value.length > 50) return "Roll number must be 50 characters or less";
        return undefined;
      default:
        return undefined;
    }
  };

  const handleBlur = (field: string, value: string) => {
    setTouched((prev) => ({ ...prev, [field]: true }));
    const error = validateField(field, value);
    setErrors((prev) => ({ ...prev, [field]: error }));
  };

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {
      name: validateField("name", name),
      email: validateField("email", email),
      roll_number: validateField("roll_number", rollNumber),
    };

    setErrors(newErrors);
    setTouched({ name: true, email: true, roll_number: true });

    return !Object.values(newErrors).some(Boolean);
  };

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();

    if (!validateForm()) return;

    onSubmit({
      name: name.trim(),
      email: email.trim(),
      roll_number: rollNumber.trim(),
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Input
        label="Name"
        placeholder="Enter student name"
        value={name}
        onChange={(e) => setName(e.target.value)}
        onBlur={() => handleBlur("name", name)}
        error={touched.name ? errors.name : undefined}
        required
        autoFocus
      />

      <Input
        label="Email"
        type="email"
        placeholder="Enter email address"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        onBlur={() => handleBlur("email", email)}
        error={touched.email ? errors.email : undefined}
        required
      />

      <Input
        label="Roll Number"
        placeholder="Enter roll number (e.g., CS-2024-001)"
        value={rollNumber}
        onChange={(e) => setRollNumber(e.target.value)}
        onBlur={() => handleBlur("roll_number", rollNumber)}
        error={touched.roll_number ? errors.roll_number : undefined}
        required
      />

      {error && (
        <div className="text-red-300 text-sm bg-red-500/20 p-3 rounded-lg" role="alert">
          {error}
        </div>
      )}

      <div className="flex gap-3 justify-end pt-4">
        <Button type="button" variant="secondary" onClick={onCancel} disabled={isLoading}>
          Cancel
        </Button>
        <Button type="submit" variant="primary" loading={isLoading}>
          {isEditMode ? "Update Student" : "Add Student"}
        </Button>
      </div>
    </form>
  );
}
