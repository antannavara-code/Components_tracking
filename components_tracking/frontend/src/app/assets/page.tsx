"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api";
import { Asset, Employee, Drone, Location, Project } from "@/types";

const statusColors: Record<string, string> = {
  available: "bg-green-100 text-green-800",
  assigned: "bg-yellow-100 text-yellow-800",
  in_drone: "bg-purple-100 text-purple-800",
  testing: "bg-indigo-100 text-indigo-800",
  maintenance: "bg-orange-100 text-orange-800",
  missing: "bg-red-100 text-red-800",
  damaged: "bg-pink-100 text-pink-800",
};

const categories = [
  "Jetson",
  "Raspberry Pi",
  "SSD",
  "SD Card",
  "USB Cable",
  "Adapter",
  "Camera",
  "Other",
];

export default function AssetsPage() {
  const [assets, setAssets] = useState<Asset[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [drones, setDrones] = useState<Drone[]>([]);
  const [locations, setLocations] = useState<Location[]>([]);
  const [projects, setProjects] = useState<Project[]>([]);
  const [search, setSearch] = useState("");
  const [filterStatus, setFilterStatus] = useState("");
  const [filterCategory, setFilterCategory] = useState("");
  const [showCreate, setShowCreate] = useState(false);
  const [showAssign, setShowAssign] = useState<number | null>(null);
  const [showHistory, setShowHistory] = useState<number | null>(null);
  const [history, setHistory] = useState<unknown[]>([]);
  const [showQrModal, setShowQrModal] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const [form, setForm] = useState({
    asset_id: "",
    category: "Jetson",
    name: "",
    serial_number: "",
    model: "",
    current_location_id: "",
    remarks: "",
  });

  const [assignForm, setAssignForm] = useState({
    employee_id: "",
    location_id: "",
    project_id: "",
    purpose: "",
  });

  const fetchAssets = () => {
    const params: Record<string, string> = {};
    if (search) params.search = search;
    if (filterStatus) params.status = filterStatus;
    if (filterCategory) params.category = filterCategory;
    api
      .get("/assets", { params })
      .then((res) => setAssets(res.data))
      .catch(console.error);
  };

  useEffect(() => {
    Promise.all([
      api.get("/employees"),
      api.get("/drones"),
      api.get("/locations"),
      api.get("/projects"),
    ])
      .then(([empRes, droneRes, locRes, projRes]) => {
        setEmployees(empRes.data);
        setDrones(droneRes.data);
        setLocations(locRes.data);
        setProjects(projRes.data);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    fetchAssets();
  }, [search, filterStatus, filterCategory]);

  const handleCreate = async () => {
    try {
      const payload: Record<string, string | number> = {
        asset_id: form.asset_id,
        category: form.category,
        name: form.name,
      };
      if (form.serial_number) payload.serial_number = form.serial_number;
      if (form.model) payload.model = form.model;
      if (form.current_location_id)
        payload.current_location_id = parseInt(form.current_location_id);
      if (form.remarks) payload.remarks = form.remarks;

      await api.post("/assets/", payload);
      setShowCreate(false);
      setForm({
        asset_id: "",
        category: "Jetson",
        name: "",
        serial_number: "",
        model: "",
        current_location_id: "",
        remarks: "",
      });
      fetchAssets();
    } catch (err) {
      alert("Error creating asset");
    }
  };

  const handleAssign = async (assetId: number) => {
    try {
      await api.post(`/assets/${assetId}/assign`, {
        employee_id: parseInt(assignForm.employee_id),
        location_id: assignForm.location_id
          ? parseInt(assignForm.location_id)
          : undefined,
        project_id: assignForm.project_id
          ? parseInt(assignForm.project_id)
          : undefined,
        purpose: assignForm.purpose || undefined,
      });
      setShowAssign(null);
      fetchAssets();
    } catch (err) {
      alert("Error assigning asset");
    }
  };

  const handleReturn = async (assetId: number) => {
    try {
      await api.post(`/assets/${assetId}/return`, {});
      fetchAssets();
    } catch (err) {
      alert("Error returning asset");
    }
  };

  const handleReportMissing = async (assetId: number) => {
    if (!confirm("Report this asset as missing?")) return;
    try {
      await api.post(`/assets/${assetId}/report-missing`, {});
      fetchAssets();
    } catch (err) {
      alert("Error reporting missing");
    }
  };

  const handleReportDamaged = async (assetId: number) => {
    if (!confirm("Report this asset as damaged?")) return;
    try {
      await api.post(`/assets/${assetId}/report-damaged`, {});
      fetchAssets();
    } catch (err) {
      alert("Error reporting damaged");
    }
  };

  const handleDelete = async (assetId: number) => {
    if (!confirm("Delete this asset?")) return;
    try {
      await api.delete(`/assets/${assetId}`);
      fetchAssets();
    } catch (err) {
      alert("Error deleting asset");
    }
  };

  const viewHistory = async (assetId: number) => {
    try {
      const res = await api.get(`/assets/${assetId}/history`);
      setHistory(res.data);
      setShowHistory(assetId);
    } catch (err) {
      alert("Error loading history");
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading assets...</div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Assets</h1>
        <button
          onClick={() => setShowCreate(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm"
        >
          + Add Asset
        </button>
      </div>

      <div className="flex gap-3 mb-4">
        <input
          type="text"
          placeholder="Search assets..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="border rounded-lg px-3 py-2 text-sm flex-1"
        />
        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          className="border rounded-lg px-3 py-2 text-sm"
        >
          <option value="">All Status</option>
          <option value="available">Available</option>
          <option value="assigned">Assigned</option>
          <option value="in_drone">In Drone</option>
          <option value="testing">Testing</option>
          <option value="maintenance">Maintenance</option>
          <option value="missing">Missing</option>
          <option value="damaged">Damaged</option>
        </select>
        <select
          value={filterCategory}
          onChange={(e) => setFilterCategory(e.target.value)}
          className="border rounded-lg px-3 py-2 text-sm"
        >
          <option value="">All Categories</option>
          {categories.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
      </div>

      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="text-left px-4 py-3 font-medium">Asset ID</th>
              <th className="text-left px-4 py-3 font-medium">Name</th>
              <th className="text-left px-4 py-3 font-medium">Category</th>
              <th className="text-left px-4 py-3 font-medium">Status</th>
              <th className="text-left px-4 py-3 font-medium">Owner</th>
              <th className="text-left px-4 py-3 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {assets.map((asset) => (
              <tr key={asset.id} className="border-b hover:bg-gray-50">
                <td className="px-4 py-3 font-mono font-medium">
                  {asset.asset_id}
                </td>
                <td className="px-4 py-3">{asset.name}</td>
                <td className="px-4 py-3">{asset.category}</td>
                <td className="px-4 py-3">
                  <span
                    className={`px-2 py-1 rounded-full text-xs font-medium ${
                      statusColors[asset.status] || "bg-gray-100"
                    }`}
                  >
                    {asset.status}
                  </span>
                </td>
                <td className="px-4 py-3">
                  {asset.current_user?.name || "-"}
                </td>
                <td className="px-4 py-3">
                  <div className="flex gap-1 flex-wrap">
                    {asset.status === "available" && (
                      <button
                        onClick={() => setShowAssign(asset.id)}
                        className="bg-blue-500 text-white px-2 py-1 rounded text-xs hover:bg-blue-600"
                      >
                        Assign
                      </button>
                    )}
                    {(asset.status === "assigned" ||
                      asset.status === "in_drone") && (
                      <button
                        onClick={() => handleReturn(asset.id)}
                        className="bg-green-500 text-white px-2 py-1 rounded text-xs hover:bg-green-600"
                      >
                        Return
                      </button>
                    )}
                    {asset.status !== "missing" &&
                      asset.status !== "damaged" && (
                        <>
                          <button
                            onClick={() => handleReportMissing(asset.id)}
                            className="bg-yellow-500 text-white px-2 py-1 rounded text-xs hover:bg-yellow-600"
                          >
                            Missing
                          </button>
                          <button
                            onClick={() => handleReportDamaged(asset.id)}
                            className="bg-orange-500 text-white px-2 py-1 rounded text-xs hover:bg-orange-600"
                          >
                            Damaged
                          </button>
                        </>
                      )}
                    <button
                      onClick={() => setShowQrModal(asset.asset_id)}
                      className="bg-indigo-500 text-white px-2 py-1 rounded text-xs hover:bg-indigo-600"
                    >
                      QR
                    </button>
                    <a
                      href={`http://localhost:8000/qr/${asset.asset_id}/print`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="bg-teal-500 text-white px-2 py-1 rounded text-xs hover:bg-teal-600 inline-block"
                    >
                      Print
                    </a>
                    <button
                      onClick={() => viewHistory(asset.id)}
                      className="bg-gray-500 text-white px-2 py-1 rounded text-xs hover:bg-gray-600"
                    >
                      History
                    </button>
                    <button
                      onClick={() => handleDelete(asset.id)}
                      className="bg-red-500 text-white px-2 py-1 rounded text-xs hover:bg-red-600"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {assets.length === 0 && (
              <tr>
                <td colSpan={6} className="text-center py-8 text-gray-400">
                  No assets found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {showCreate && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h2 className="text-lg font-bold mb-4">Create New Asset</h2>
            <div className="space-y-3">
              <input
                placeholder="Asset ID (e.g. JET-001)"
                value={form.asset_id}
                onChange={(e) => setForm({ ...form, asset_id: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <select
                value={form.category}
                onChange={(e) => setForm({ ...form, category: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              >
                {categories.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
              <input
                placeholder="Name"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <input
                placeholder="Serial Number"
                value={form.serial_number}
                onChange={(e) =>
                  setForm({ ...form, serial_number: e.target.value })
                }
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <input
                placeholder="Model"
                value={form.model}
                onChange={(e) => setForm({ ...form, model: e.target.value })}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
              <select
                value={form.current_location_id}
                onChange={(e) =>
                  setForm({ ...form, current_location_id: e.target.value })
                }
                className="w-full border rounded-lg px-3 py-2 text-sm"
              >
                <option value="">Select Location</option>
                {locations.map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.name}
                  </option>
                ))}
              </select>
              <input
                placeholder="Remarks"
                value={form.remarks}
                onChange={(e) => setForm({ ...form, remarks: e.target.value })}
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

      {showAssign && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h2 className="text-lg font-bold mb-4">Assign Asset</h2>
            <div className="space-y-3">
              <select
                value={assignForm.employee_id}
                onChange={(e) =>
                  setAssignForm({ ...assignForm, employee_id: e.target.value })
                }
                className="w-full border rounded-lg px-3 py-2 text-sm"
              >
                <option value="">Select Employee</option>
                {employees.map((e) => (
                  <option key={e.id} value={e.id}>
                    {e.name}
                  </option>
                ))}
              </select>
              <select
                value={assignForm.location_id}
                onChange={(e) =>
                  setAssignForm({ ...assignForm, location_id: e.target.value })
                }
                className="w-full border rounded-lg px-3 py-2 text-sm"
              >
                <option value="">Select Location</option>
                {locations.map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.name}
                  </option>
                ))}
              </select>
              <select
                value={assignForm.project_id}
                onChange={(e) =>
                  setAssignForm({ ...assignForm, project_id: e.target.value })
                }
                className="w-full border rounded-lg px-3 py-2 text-sm"
              >
                <option value="">Select Project</option>
                {projects.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
              <input
                placeholder="Purpose"
                value={assignForm.purpose}
                onChange={(e) =>
                  setAssignForm({ ...assignForm, purpose: e.target.value })
                }
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
            </div>
            <div className="flex justify-end gap-2 mt-4">
              <button
                onClick={() => setShowAssign(null)}
                className="px-4 py-2 text-sm border rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={() => handleAssign(showAssign)}
                className="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Assign
              </button>
            </div>
          </div>
        </div>
      )}

      {showHistory && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-lg max-h-[80vh] overflow-auto">
            <h2 className="text-lg font-bold mb-4">Asset History</h2>
            {history.length === 0 ? (
              <p className="text-gray-400">No history records</p>
            ) : (
              <div className="space-y-2">
                {(history as { id: number; action: string; created_at: string; purpose: string | null; remarks: string | null }[]).map(
                  (m) => (
                    <div key={m.id} className="border rounded-lg p-3 text-sm">
                      <div className="flex justify-between">
                        <span className="font-medium">{m.action}</span>
                        <span className="text-gray-400 text-xs">
                          {new Date(m.created_at).toLocaleString()}
                        </span>
                      </div>
                      {m.purpose && (
                        <p className="text-gray-500 mt-1">
                          Purpose: {m.purpose}
                        </p>
                      )}
                      {m.remarks && (
                        <p className="text-gray-500">
                          Remarks: {m.remarks}
                        </p>
                      )}
                    </div>
                  )
                )}
              </div>
            )}
            <div className="flex justify-end mt-4">
              <button
                onClick={() => setShowHistory(null)}
                className="px-4 py-2 text-sm border rounded-lg hover:bg-gray-50"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {showQrModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-sm text-center">
            <h2 className="text-lg font-bold mb-1">QR Code</h2>
            <p className="font-mono text-sm text-gray-500 mb-4">{showQrModal}</p>
            <img
              src={`http://localhost:8000/qr/${showQrModal}/image`}
              alt={`QR for ${showQrModal}`}
              className="mx-auto mb-4"
              width={200}
              height={200}
            />
            <div className="flex gap-2 justify-center">
              <a
                href={`http://localhost:8000/qr/${showQrModal}/print`}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700"
              >
                Print Label
              </a>
              <a
                href={`http://localhost:8000/qr/${showQrModal}/image`}
                download={`QR_${showQrModal}.png`}
                className="bg-gray-800 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700"
              >
                Download
              </a>
              <button
                onClick={() => setShowQrModal(null)}
                className="border px-4 py-2 rounded-lg text-sm hover:bg-gray-50"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
