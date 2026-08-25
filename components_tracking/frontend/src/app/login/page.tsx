"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import api from "@/lib/api";

export default function LoginPage() {
  const router = useRouter();
  const [isRegister, setIsRegister] = useState(false);
  const [form, setForm] = useState({
    username: "",
    password: "",
    role: "employee",
  });
  const [error, setError] = useState("");

  const handleSubmit = async () => {
    setError("");
    try {
      if (isRegister) {
        await api.post("/auth/register", form);
        setIsRegister(false);
        setError("Registration successful! Now login.");
      } else {
        const res = await api.post("/auth/login", {
          username: form.username,
          password: form.password,
        });
        localStorage.setItem("token", res.data.access_token);
        localStorage.setItem("user", JSON.stringify(res.data.user));
        router.push("/");
      }
    } catch {
      setError(isRegister ? "Registration failed" : "Invalid credentials");
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="bg-white rounded-xl shadow-lg p-8 w-full max-w-sm">
        <h1 className="text-xl font-bold text-center mb-1">QR Asset Tracker</h1>
        <p className="text-gray-400 text-sm text-center mb-6">
          {isRegister ? "Create account" : "Sign in"}
        </p>
        {error && (
          <div
            className={`text-sm mb-3 p-2 rounded ${
              error.includes("successful")
                ? "bg-green-50 text-green-700"
                : "bg-red-50 text-red-700"
            }`}
          >
            {error}
          </div>
        )}
        <div className="space-y-3">
          <input
            placeholder="Username"
            value={form.username}
            onChange={(e) => setForm({ ...form, username: e.target.value })}
            className="w-full border rounded-lg px-3 py-2 text-sm"
          />
          <input
            placeholder="Password"
            type="password"
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            className="w-full border rounded-lg px-3 py-2 text-sm"
          />
          {isRegister && (
            <select
              value={form.role}
              onChange={(e) => setForm({ ...form, role: e.target.value })}
              className="w-full border rounded-lg px-3 py-2 text-sm"
            >
              <option value="employee">Employee</option>
              <option value="admin">Admin</option>
              <option value="manager">Manager</option>
            </select>
          )}
        </div>
        <button
          onClick={handleSubmit}
          className="w-full bg-blue-600 text-white py-2.5 rounded-lg mt-4 hover:bg-blue-700 text-sm font-medium"
        >
          {isRegister ? "Register" : "Login"}
        </button>
        <p className="text-center text-sm text-gray-500 mt-3">
          {isRegister ? "Already have an account?" : "No account?"}{" "}
          <button
            onClick={() => {
              setIsRegister(!isRegister);
              setError("");
            }}
            className="text-blue-600 hover:underline"
          >
            {isRegister ? "Login" : "Register"}
          </button>
        </p>
      </div>
    </div>
  );
}
