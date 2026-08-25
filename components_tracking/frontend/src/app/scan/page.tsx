"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import api from "@/lib/api";
import { Asset, Employee, Drone, Location, Project } from "@/types";

export default function ScanPage() {
  const router = useRouter();
  const scannerRef = useRef<HTMLDivElement>(null);
  const html5QrCodeRef = useRef<unknown>(null);
  const [scanning, setScanning] = useState(false);
  const [scannedAsset, setScannedAsset] = useState<Asset | null>(null);
  const [error, setError] = useState("");
  const [manualId, setManualId] = useState("");

  const [employees, setEmployees] = useState<Employee[]>([]);
  const [drones, setDrones] = useState<Drone[]>([]);
  const [locations, setLocations] = useState<Location[]>([]);
  const [projects, setProjects] = useState<Project[]>([]);

  const [showAction, setShowAction] = useState<string | null>(null);
  const [actionForm, setActionForm] = useState({
    employee_id: "",
    to_employee_id: "",
    drone_id: "",
    location_id: "",
    project_id: "",
    purpose: "",
    description: "",
    remarks: "",
  });
  const [actionLoading, setActionLoading] = useState(false);
  const [successMsg, setSuccessMsg] = useState("");

  const loadFormData = useCallback(() => {
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
      .catch(console.error);
  }, []);

  useEffect(() => {
    loadFormData();
    return () => {
      if (html5QrCodeRef.current) {
        try {
          (html5QrCodeRef.current as { stop: () => Promise<void> }).stop().catch(() => {});
        } catch {}
      }
    };
  }, [loadFormData]);

  const startScanner = async () => {
    setError("");
    setScanning(true);
    try {
      const { Html5Qrcode } = await import("html5-qrcode");
      const html5QrCode = new Html5Qrcode("qr-reader");
      html5QrCodeRef.current = html5QrCode;

      await html5QrCode.start(
        { facingMode: "environment" },
        { fps: 10, qrbox: { width: 250, height: 250 } },
        async (decodedText: string) => {
          await html5QrCode.stop().catch(() => {});
          html5QrCodeRef.current = null;
          setScanning(false);
          lookupAsset(decodedText.trim());
        },
        () => {}
      );
    } catch (err) {
      setScanning(false);
      setError("Camera access denied or not available. Use manual entry below.");
    }
  };

  const stopScanner = async () => {
    if (html5QrCodeRef.current) {
      try {
        await (html5QrCodeRef.current as { stop: () => Promise<void> }).stop();
      } catch {}
      html5QrCodeRef.current = null;
    }
    setScanning(false);
  };

  const lookupAsset = async (assetId: string) => {
    try {
      const res = await api.get(`/assets/by-asset-id/${assetId}`);
      setScannedAsset(res.data);
      setShowAction(null);
      setSuccessMsg("");
    } catch {
      setError(`Asset "${assetId}" not found`);
    }
  };

  const handleManualLookup = () => {
    if (manualId.trim()) {
      lookupAsset(manualId.trim());
      setManualId("");
    }
  };

  const resetScan = () => {
    setScannedAsset(null);
    setShowAction(null);
    setError("");
    setSuccessMsg("");
    setActionForm({
      employee_id: "",
      to_employee_id: "",
      drone_id: "",
      location_id: "",
      project_id: "",
      purpose: "",
      description: "",
      remarks: "",
    });
  };

  const executeAction = async (action: string) => {
    if (!scannedAsset) return;
    setActionLoading(true);
    try {
      switch (action) {
        case "assign":
          await api.post(`/assets/${scannedAsset.id}/assign`, {
            employee_id: parseInt(actionForm.employee_id),
            location_id: actionForm.location_id ? parseInt(actionForm.location_id) : undefined,
            project_id: actionForm.project_id ? parseInt(actionForm.project_id) : undefined,
            purpose: actionForm.purpose || undefined,
          });
          setSuccessMsg(`Asset assigned to employee successfully`);
          break;
        case "transfer":
          await api.post(`/assets/${scannedAsset.id}/transfer`, {
            to_employee_id: parseInt(actionForm.to_employee_id),
            purpose: actionForm.purpose || undefined,
          });
          setSuccessMsg("Asset transferred successfully");
          break;
        case "return":
          await api.post(`/assets/${scannedAsset.id}/return`, {
            location_id: actionForm.location_id ? parseInt(actionForm.location_id) : undefined,
          });
          setSuccessMsg("Asset returned successfully");
          break;
        case "assign-drone":
          await api.post(`/assets/${scannedAsset.id}/assign-drone`, {
            drone_id: parseInt(actionForm.drone_id),
            purpose: actionForm.purpose || undefined,
          });
          setSuccessMsg("Asset installed in drone successfully");
          break;
        case "remove-drone":
          await api.post(`/assets/${scannedAsset.id}/remove-drone`, {});
          setSuccessMsg("Asset removed from drone successfully");
          break;
        case "report-missing":
          await api.post(`/assets/${scannedAsset.id}/report-missing`, {
            description: actionForm.description || undefined,
          });
          setSuccessMsg("Asset reported as missing");
          break;
        case "report-damaged":
          await api.post(`/assets/${scannedAsset.id}/report-damaged`, {
            description: actionForm.description || undefined,
          });
          setSuccessMsg("Asset reported as damaged");
          break;
      }
      const res = await api.get(`/assets/${scannedAsset.id}`);
      setScannedAsset(res.data);
      setShowAction(null);
    } catch {
      setError("Action failed. Please try again.");
    } finally {
      setActionLoading(false);
    }
  };

  const statusColor: Record<string, string> = {
    available: "bg-green-100 text-green-800 border-green-300",
    assigned: "bg-yellow-100 text-yellow-800 border-yellow-300",
    in_drone: "bg-purple-100 text-purple-800 border-purple-300",
    testing: "bg-indigo-100 text-indigo-800 border-indigo-300",
    maintenance: "bg-orange-100 text-orange-800 border-orange-300",
    missing: "bg-red-100 text-red-800 border-red-300",
    damaged: "bg-pink-100 text-pink-800 border-pink-300",
  };

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-2">QR Scanner</h1>
      <p className="text-gray-500 text-sm mb-6">
        Scan a QR code on any asset to view details and perform actions.
      </p>

      {successMsg && (
        <div className="bg-green-50 border border-green-300 text-green-800 rounded-lg p-4 mb-4 text-sm">
          {successMsg}
          <button onClick={() => setSuccessMsg("")} className="ml-2 underline">dismiss</button>
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-300 text-red-800 rounded-lg p-4 mb-4 text-sm">
          {error}
          <button onClick={() => setError("")} className="ml-2 underline">dismiss</button>
        </div>
      )}

      {!scannedAsset && (
        <>
          <div className="bg-white rounded-xl border shadow-sm p-6 mb-4">
            <div id="qr-reader" ref={scannerRef} className="mb-4" />
            <div className="flex gap-2">
              {!scanning ? (
                <button
                  onClick={startScanner}
                  className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 font-medium flex-1"
                >
                  Start Camera Scan
                </button>
              ) : (
                <button
                  onClick={stopScanner}
                  className="bg-red-600 text-white px-6 py-3 rounded-lg hover:bg-red-700 font-medium flex-1"
                >
                  Stop Scanner
                </button>
              )}
            </div>
          </div>

          <div className="bg-white rounded-xl border shadow-sm p-6">
            <p className="text-sm text-gray-500 mb-3">Or enter Asset ID manually:</p>
            <div className="flex gap-2">
              <input
                placeholder="e.g. JET-001"
                value={manualId}
                onChange={(e) => setManualId(e.target.value.toUpperCase())}
                onKeyDown={(e) => e.key === "Enter" && handleManualLookup()}
                className="flex-1 border rounded-lg px-3 py-2 text-sm font-mono"
              />
              <button
                onClick={handleManualLookup}
                className="bg-gray-800 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700"
              >
                Look Up
              </button>
            </div>
          </div>
        </>
      )}

      {scannedAsset && (
        <div className="bg-white rounded-xl border shadow-sm overflow-hidden">
          <div className="bg-gray-50 border-b px-6 py-4 flex items-center justify-between">
            <div>
              <h2 className="text-lg font-bold font-mono">{scannedAsset.asset_id}</h2>
              <p className="text-gray-500 text-sm">{scannedAsset.name}</p>
            </div>
            <button
              onClick={resetScan}
              className="text-sm text-blue-600 hover:underline"
            >
              Scan Another
            </button>
          </div>

          <div className="p-6">
            <div className="grid grid-cols-2 gap-3 mb-6 text-sm">
              <div><span className="text-gray-500">Category:</span> {scannedAsset.category}</div>
              <div><span className="text-gray-500">Model:</span> {scannedAsset.model || "N/A"}</div>
              <div><span className="text-gray-500">Serial:</span> {scannedAsset.serial_number || "N/A"}</div>
              <div>
                <span className="text-gray-500">Status: </span>
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium border ${statusColor[scannedAsset.status] || ""}`}>
                  {scannedAsset.status}
                </span>
              </div>
              <div><span className="text-gray-500">Condition:</span> {scannedAsset.condition_type}</div>
              <div><span className="text-gray-500">Owner:</span> {scannedAsset.current_user?.name || "None"}</div>
              <div><span className="text-gray-500">Location:</span> {scannedAsset.current_location?.name || "None"}</div>
              <div><span className="text-gray-500">Drone:</span> {scannedAsset.current_drone?.name || "None"}</div>
              <div><span className="text-gray-500">Project:</span> {scannedAsset.project?.name || "None"}</div>
            </div>

            {scannedAsset.status !== "missing" && scannedAsset.status !== "damaged" && (
              <div className="grid grid-cols-2 gap-2">
                {scannedAsset.status === "available" && (
                  <button
                    onClick={() => setShowAction("assign")}
                    className="bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 text-sm font-medium"
                  >
                    Assign to Employee
                  </button>
                )}
                {scannedAsset.status === "assigned" && (
                  <>
                    <button
                      onClick={() => setShowAction("transfer")}
                      className="bg-yellow-500 text-white py-3 rounded-lg hover:bg-yellow-600 text-sm font-medium"
                    >
                      Transfer
                    </button>
                    <button
                      onClick={() => setShowAction("return")}
                      className="bg-green-600 text-white py-3 rounded-lg hover:bg-green-700 text-sm font-medium"
                    >
                      Return
                    </button>
                    <button
                      onClick={() => setShowAction("assign-drone")}
                      className="bg-purple-600 text-white py-3 rounded-lg hover:bg-purple-700 text-sm font-medium"
                    >
                      Install in Drone
                    </button>
                  </>
                )}
                {scannedAsset.status === "in_drone" && (
                  <>
                    <button
                      onClick={() => setShowAction("remove-drone")}
                      className="bg-orange-600 text-white py-3 rounded-lg hover:bg-orange-700 text-sm font-medium"
                    >
                      Remove from Drone
                    </button>
                    <button
                      onClick={() => setShowAction("return")}
                      className="bg-green-600 text-white py-3 rounded-lg hover:bg-green-700 text-sm font-medium"
                    >
                      Return
                    </button>
                  </>
                )}
                <button
                  onClick={() => setShowAction("report-missing")}
                  className="bg-red-500 text-white py-3 rounded-lg hover:bg-red-600 text-sm font-medium"
                >
                  Report Missing
                </button>
                <button
                  onClick={() => setShowAction("report-damaged")}
                  className="bg-pink-600 text-white py-3 rounded-lg hover:bg-pink-700 text-sm font-medium"
                >
                  Report Damaged
                </button>
              </div>
            )}

            {showAction && (
              <div className="mt-4 border-t pt-4">
                <h3 className="font-bold mb-3 text-sm capitalize">
                  {showAction.replace("-", " ")}
                </h3>

                {showAction === "assign" && (
                  <div className="space-y-3">
                    <select
                      value={actionForm.employee_id}
                      onChange={(e) => setActionForm({ ...actionForm, employee_id: e.target.value })}
                      className="w-full border rounded-lg px-3 py-2 text-sm"
                    >
                      <option value="">Select Employee</option>
                      {employees.map((emp) => (
                        <option key={emp.id} value={emp.id}>{emp.name}</option>
                      ))}
                    </select>
                    <select
                      value={actionForm.location_id}
                      onChange={(e) => setActionForm({ ...actionForm, location_id: e.target.value })}
                      className="w-full border rounded-lg px-3 py-2 text-sm"
                    >
                      <option value="">Select Location</option>
                      {locations.map((loc) => (
                        <option key={loc.id} value={loc.id}>{loc.name}</option>
                      ))}
                    </select>
                    <select
                      value={actionForm.project_id}
                      onChange={(e) => setActionForm({ ...actionForm, project_id: e.target.value })}
                      className="w-full border rounded-lg px-3 py-2 text-sm"
                    >
                      <option value="">Select Project</option>
                      {projects.map((p) => (
                        <option key={p.id} value={p.id}>{p.name}</option>
                      ))}
                    </select>
                    <input
                      placeholder="Purpose"
                      value={actionForm.purpose}
                      onChange={(e) => setActionForm({ ...actionForm, purpose: e.target.value })}
                      className="w-full border rounded-lg px-3 py-2 text-sm"
                    />
                  </div>
                )}

                {showAction === "transfer" && (
                  <div className="space-y-3">
                    <select
                      value={actionForm.to_employee_id}
                      onChange={(e) => setActionForm({ ...actionForm, to_employee_id: e.target.value })}
                      className="w-full border rounded-lg px-3 py-2 text-sm"
                    >
                      <option value="">Transfer to Employee</option>
                      {employees
                        .filter((emp) => emp.id !== scannedAsset?.current_user_id)
                        .map((emp) => (
                          <option key={emp.id} value={emp.id}>{emp.name}</option>
                        ))}
                    </select>
                    <input
                      placeholder="Purpose"
                      value={actionForm.purpose}
                      onChange={(e) => setActionForm({ ...actionForm, purpose: e.target.value })}
                      className="w-full border rounded-lg px-3 py-2 text-sm"
                    />
                  </div>
                )}

                {showAction === "return" && (
                  <div className="space-y-3">
                    <select
                      value={actionForm.location_id}
                      onChange={(e) => setActionForm({ ...actionForm, location_id: e.target.value })}
                      className="w-full border rounded-lg px-3 py-2 text-sm"
                    >
                      <option value="">Return to Location</option>
                      {locations.map((loc) => (
                        <option key={loc.id} value={loc.id}>{loc.name}</option>
                      ))}
                    </select>
                  </div>
                )}

                {showAction === "assign-drone" && (
                  <div className="space-y-3">
                    <select
                      value={actionForm.drone_id}
                      onChange={(e) => setActionForm({ ...actionForm, drone_id: e.target.value })}
                      className="w-full border rounded-lg px-3 py-2 text-sm"
                    >
                      <option value="">Select Drone</option>
                      {drones.filter((d) => d.status === "active").map((drone) => (
                        <option key={drone.id} value={drone.id}>{drone.drone_id} - {drone.name}</option>
                      ))}
                    </select>
                    <input
                      placeholder="Purpose"
                      value={actionForm.purpose}
                      onChange={(e) => setActionForm({ ...actionForm, purpose: e.target.value })}
                      className="w-full border rounded-lg px-3 py-2 text-sm"
                    />
                  </div>
                )}

                {(showAction === "report-missing" || showAction === "report-damaged") && (
                  <div className="space-y-3">
                    <textarea
                      placeholder="Describe the issue..."
                      value={actionForm.description}
                      onChange={(e) => setActionForm({ ...actionForm, description: e.target.value })}
                      className="w-full border rounded-lg px-3 py-2 text-sm"
                      rows={3}
                    />
                  </div>
                )}

                <div className="flex gap-2 mt-4">
                  <button
                    onClick={() => setShowAction(null)}
                    className="px-4 py-2 text-sm border rounded-lg hover:bg-gray-50"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => executeAction(showAction)}
                    disabled={actionLoading}
                    className="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                  >
                    {actionLoading ? "Processing..." : "Confirm"}
                  </button>
                </div>
              </div>
            )}

            <div className="mt-4 border-t pt-4 flex gap-2">
              <a
                href={`http://localhost:8000/qr/${scannedAsset.asset_id}/print`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-blue-600 hover:underline"
              >
                Print QR Label
              </a>
              <span className="text-gray-300">|</span>
              <a
                href={`http://localhost:8000/qr/${scannedAsset.asset_id}/image`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-blue-600 hover:underline"
              >
                View QR Image
              </a>
              <span className="text-gray-300">|</span>
              <button
                onClick={() => router.push(`/assets`)}
                className="text-sm text-blue-600 hover:underline"
              >
                Full Asset Details
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
