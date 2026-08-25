"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api";
import { Location } from "@/types";

export default function LocationsPage() {
  const [locations, setLocations] = useState<Location[]>([]);
  const [showCreate, setShowCreate] = useState(false);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({
    name: "",
    building: "",
    room: "",
    description: "",
  });

  const fetchLocations = () => {
    return api
      .get("/locations")
      .then((res) => setLocations(res.data))
      .catch(console.error);
  };

  useEffect(() => {
    fetchLocations().finally(() => setLoading(false));
  }, []);

  const handleCreate = async () => {
    try {
      await api.post("/locations/", form);
      setShowCreate(false);
      setForm({ name: "", building: "", room: "", description: "" });
      fetchLocations();
    } catch {
      alert("Error creating location");
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Delete this location?")) return;
    try {
      await api.delete(`/locations/${id}`);
      fetchLocations();
    } catch {
      alert("Error deleting location");
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
        <h1 className="text-2xl font-bold">Locations</h1>
        <button
          onClick={() => setShowCreate(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm"
        >
          + Add Location
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="text-left px-4 py-3 font-medium">Name</th>
              <th className="text-left px-4 py-3 font-medium">Building</th>
              <th className="text-left px-4 py-3 font-medium">Room</th>
              <th className="text-left px-4 py-3 font-medium">Description</th>
              <th className="text-left px-4 py-3 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {locations.map((loc) => (
              <tr key={loc.id} className="border-b hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{loc.name}</td>
                <td className="px-4 py-3">{loc.building || "-"}</td>
                <td className="px-4 py-3">{loc.room || "-"}</td>
                <td className="px-4 py-3">{loc.description || "-"}</td>
                <td className="px-4 py-3">
                  <button
                    onClick={() => handleDelete(loc.id)}
                    className="bg-red-500 text-white px-2 py-1 rounded text-xs hover:bg-red-600"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
            {locations.length === 0 && (
              <tr>
                <td colSpan={5} className="text-center py-8 text-gray-400">
                  No locations found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {showCreate && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h2 className="text-lg font-bold mb-4">Add Location</h2>
            <div className="space-y-3">
              <input
                placeholder="Name (e.g. Office, Lab)"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <input
                placeholder="Building"
                value={form.building}
                onChange={(e) =>
                  setForm({ ...form, building: e.target.value })
                }
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <input
                placeholder="Room"
                value={form.room}
                onChange={(e) => setForm({ ...form, room: e.target.value })}
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
