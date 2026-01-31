"""Tests for Student CRUD API endpoints."""
import pytest
from fastapi.testclient import TestClient


class TestHealthEndpoint:
    """Tests for the health check endpoint."""

    def test_health_check(self, client: TestClient):
        """Test that health endpoint returns healthy status."""
        response = client.get("/api/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "timestamp" in data


class TestCreateStudent:
    """Tests for POST /api/students endpoint."""

    def test_create_student_success(self, client: TestClient):
        """Test successful student creation."""
        student_data = {
            "name": "John Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        }
        response = client.post("/api/students", json=student_data)
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "John Doe"
        assert data["email"] == "john@example.com"
        assert data["roll_number"] == "CS-2024-001"
        assert "id" in data
        assert "created_at" in data
        assert "updated_at" in data

    def test_create_student_duplicate_email(self, client: TestClient):
        """Test that duplicate email returns 409 error."""
        student_data = {
            "name": "John Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        }
        client.post("/api/students", json=student_data)

        # Try to create another student with same email
        duplicate_data = {
            "name": "Jane Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-002"
        }
        response = client.post("/api/students", json=duplicate_data)
        assert response.status_code == 409

    def test_create_student_duplicate_roll_number(self, client: TestClient):
        """Test that duplicate roll number returns 409 error."""
        student_data = {
            "name": "John Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        }
        client.post("/api/students", json=student_data)

        # Try to create another student with same roll number
        duplicate_data = {
            "name": "Jane Doe",
            "email": "jane@example.com",
            "roll_number": "CS-2024-001"
        }
        response = client.post("/api/students", json=duplicate_data)
        assert response.status_code == 409

    def test_create_student_invalid_email(self, client: TestClient):
        """Test that invalid email returns 422 validation error."""
        student_data = {
            "name": "John Doe",
            "email": "not-an-email",
            "roll_number": "CS-2024-001"
        }
        response = client.post("/api/students", json=student_data)
        assert response.status_code == 422

    def test_create_student_missing_name(self, client: TestClient):
        """Test that missing name returns 422 validation error."""
        student_data = {
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        }
        response = client.post("/api/students", json=student_data)
        assert response.status_code == 422


class TestListStudents:
    """Tests for GET /api/students endpoint."""

    def test_list_students_empty(self, client: TestClient):
        """Test listing students when database is empty."""
        response = client.get("/api/students")
        assert response.status_code == 200
        assert response.json() == []

    def test_list_students_with_data(self, client: TestClient):
        """Test listing students returns all students."""
        # Create two students
        client.post("/api/students", json={
            "name": "John Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        })
        client.post("/api/students", json={
            "name": "Jane Doe",
            "email": "jane@example.com",
            "roll_number": "CS-2024-002"
        })

        response = client.get("/api/students")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    def test_list_students_search_by_name(self, client: TestClient):
        """Test search filters students by name."""
        client.post("/api/students", json={
            "name": "John Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        })
        client.post("/api/students", json={
            "name": "Jane Smith",
            "email": "jane@example.com",
            "roll_number": "CS-2024-002"
        })

        response = client.get("/api/students?search=john")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "John Doe"

    def test_list_students_search_by_email(self, client: TestClient):
        """Test search filters students by email."""
        client.post("/api/students", json={
            "name": "John Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        })

        response = client.get("/api/students?search=john@example")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1


class TestGetStudent:
    """Tests for GET /api/students/{id} endpoint."""

    def test_get_student_success(self, client: TestClient):
        """Test getting a student by ID."""
        create_response = client.post("/api/students", json={
            "name": "John Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        })
        student_id = create_response.json()["id"]

        response = client.get(f"/api/students/{student_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "John Doe"

    def test_get_student_not_found(self, client: TestClient):
        """Test getting non-existent student returns 404."""
        response = client.get("/api/students/9999")
        assert response.status_code == 404


class TestUpdateStudent:
    """Tests for PUT /api/students/{id} endpoint."""

    def test_update_student_success(self, client: TestClient):
        """Test full update of a student."""
        create_response = client.post("/api/students", json={
            "name": "John Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        })
        student_id = create_response.json()["id"]

        update_data = {
            "name": "John Updated",
            "email": "john.updated@example.com",
            "roll_number": "CS-2024-999"
        }
        response = client.put(f"/api/students/{student_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "John Updated"
        assert data["email"] == "john.updated@example.com"

    def test_update_student_not_found(self, client: TestClient):
        """Test updating non-existent student returns 404."""
        update_data = {
            "name": "John",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        }
        response = client.put("/api/students/9999", json=update_data)
        assert response.status_code == 404


class TestPatchStudent:
    """Tests for PATCH /api/students/{id} endpoint."""

    def test_patch_student_partial_update(self, client: TestClient):
        """Test partial update of a student."""
        create_response = client.post("/api/students", json={
            "name": "John Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        })
        student_id = create_response.json()["id"]

        # Update only the name
        response = client.patch(f"/api/students/{student_id}", json={"name": "John Updated"})
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "John Updated"
        assert data["email"] == "john@example.com"  # Unchanged

    def test_patch_student_not_found(self, client: TestClient):
        """Test patching non-existent student returns 404."""
        response = client.patch("/api/students/9999", json={"name": "John"})
        assert response.status_code == 404


class TestDeleteStudent:
    """Tests for DELETE /api/students/{id} endpoint."""

    def test_delete_student_success(self, client: TestClient):
        """Test deleting a student."""
        create_response = client.post("/api/students", json={
            "name": "John Doe",
            "email": "john@example.com",
            "roll_number": "CS-2024-001"
        })
        student_id = create_response.json()["id"]

        response = client.delete(f"/api/students/{student_id}")
        assert response.status_code == 200
        assert response.json()["message"] == "Student deleted successfully"

        # Verify student is deleted
        get_response = client.get(f"/api/students/{student_id}")
        assert get_response.status_code == 404

    def test_delete_student_not_found(self, client: TestClient):
        """Test deleting non-existent student returns 404."""
        response = client.delete("/api/students/9999")
        assert response.status_code == 404
