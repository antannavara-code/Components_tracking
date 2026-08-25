"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api";
import { Employee } from "@/types";

export default function EmployeesPage() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [showCreate, setShowCreate] = useState(false);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({
    name: "",
    email: "",
    department: "",
    phone: "",
  });

  const fetchEmployees = () => {
    return api
      .get("/employees")
      .then((res) => setEmployees(res.data))
      .catch(console.error);
  };

  useEffect(() => {
    fetchEmployees().finally(() => setLoading(false));
  }, []);

  const handleCreate = async () => {
    try {
      await api.post("/employees/", form);
      setShowCreate(false);
      setForm({ name: "", email: "", department: "", phone: "" });
      fetchEmployees();
    } catch {
      alert("Error creating employee");
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Delete this employee?")) return;
    try {
      await api.delete(`/employees/${id}`);
      fetchEmployees();
    } catch {
      alert("Error deleting employee");
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading...</div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Employees</h1>
        <button
          onClick={() => setShowCreate(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm"
        >
          + Add Employee
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="text-left px-4 py-3 font-medium">Name</th>
              <th className="text-left px-4 py-3 font-medium">Email</th>
              <th className="text-left px-4 py-3 font-medium">Department</th>
              <th className="text-left px-4 py-3 font-medium">Phone</th>
              <th className="text-left px-4 py-3 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {employees.map((emp) => (
              <tr key={emp.id} className="border-b hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{emp.name}</td>
                <td className="px-4 py-3">{emp.email}</td>
                <td className="px-4 py-3">{emp.department || "-"}</td>
                <td className="px-4 py-3">{emp.phone || "-"}</td>
                <td className="px-4 py-3">
                  <button
                    onClick={() => handleDelete(emp.id)}
                    className="bg-red-500 text-white px-2 py-1 rounded text-xs hover:bg-red-600"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
            {employees.length === 0 && (
              <tr>
                <td colSpan={5} className="text-center py-8 text-gray-400">
                  No employees found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {showCreate && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h2 className="text-lg font-bold mb-4">Add Employee</h2>
            <div className="space-y-3">
              <input
                placeholder="Name"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <input
                placeholder="Email"
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <input
                placeholder="Department"
                value={form.department}
                onChange={(e) =>
                  setForm({ ...form, department: e.target.value })
                }
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <input
                placeholder="Phone"
                value={form.phone}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
            </div>
            <div className="flex justify-end gap-2 mt-4">
              <button
                onClick={() => setShowCreate(false)}
                className="px-4 py-2 text-sm border rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleCreate}
                className="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Create
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
