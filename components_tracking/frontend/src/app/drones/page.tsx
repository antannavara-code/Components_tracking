"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api";
import { Drone } from "@/types";

export default function DronesPage() {
  const [drones, setDrones] = useState<Drone[]>([]);
  const [showCreate, setShowCreate] = useState(false);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({
    drone_id: "",
    name: "",
    model: "",
    description: "",
  });

  const fetchDrones = () => {
    return api
      .get("/drones")
      .then((res) => setDrones(res.data))
      .catch(console.error);
  };

  useEffect(() => {
    fetchDrones().finally(() => setLoading(false));
  }, []);

  const handleCreate = async () => {
    try {
      await api.post("/drones/", form);
      setShowCreate(false);
      setForm({ drone_id: "", name: "", model: "", description: "" });
      fetchDrones();
    } catch {
      alert("Error creating drone");
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Delete this drone?")) return;
    try {
      await api.delete(`/drones/${id}`);
      fetchDrones();
    } catch {
      alert("Error deleting drone");
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
        <h1 className="text-2xl font-bold">Drones</h1>
        <button
          onClick={() => setShowCreate(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm"
        >
          + Add Drone
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="text-left px-4 py-3 font-medium">Drone ID</th>
              <th className="text-left px-4 py-3 font-medium">Name</th>
              <th className="text-left px-4 py-3 font-medium">Model</th>
              <th className="text-left px-4 py-3 font-medium">Status</th>
              <th className="text-left px-4 py-3 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {drones.map((drone) => (
              <tr key={drone.id} className="border-b hover:bg-gray-50">
                <td className="px-4 py-3 font-mono font-medium">
                  {drone.drone_id}
                </td>
                <td className="px-4 py-3">{drone.name}</td>
                <td className="px-4 py-3">{drone.model || "-"}</td>
                <td className="px-4 py-3">
                  <span
                    className={`px-2 py-1 rounded-full text-xs font-medium ${
                      drone.status === "active"
                        ? "bg-green-100 text-green-800"
                        : "bg-red-100 text-red-800"
                    }`}
                  >
                    {drone.status}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <button
                    onClick={() => handleDelete(drone.id)}
                    className="bg-red-500 text-white px-2 py-1 rounded text-xs hover:bg-red-600"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
            {drones.length === 0 && (
              <tr>
                <td colSpan={5} className="text-center py-8 text-gray-400">
                  No drones found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {showCreate && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h2 className="text-lg font-bold mb-4">Add Drone</h2>
            <div className="space-y-3">
              <input
                placeholder="Drone ID (e.g. DRONE-01)"
                value={form.drone_id}
                onChange={(e) =>
                  setForm({ ...form, drone_id: e.target.value })
                }
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <input
                placeholder="Name"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <input
                placeholder="Model"
                value={form.model}
                onChange={(e) => setForm({ ...form, model: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <input
                placeholder="Description"
                value={form.description}
                onChange={(e) =>
                  setForm({ ...form, description: e.target.value })
                }
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
