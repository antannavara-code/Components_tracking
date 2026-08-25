"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import api from "@/lib/api";
import { DashboardStats, Asset } from "@/types";

const statCards = [
  { key: "total_assets", label: "Total Assets", color: "bg-blue-500", icon: "📦" },
  { key: "available", label: "Available", color: "bg-green-500", icon: "✅" },
  { key: "assigned", label: "Assigned / In Use", color: "bg-yellow-500", icon: "👤" },
  { key: "in_drone", label: "In Drones", color: "bg-purple-500", icon: "🛸" },
  { key: "testing", label: "Under Testing", color: "bg-indigo-500", icon: "🔬" },
  { key: "maintenance", label: "Maintenance", color: "bg-orange-500", icon: "🔧" },
  { key: "missing", label: "Missing", color: "bg-red-500", icon: "⚠️" },
  { key: "damaged", label: "Damaged", color: "bg-pink-500", icon: "💔" },
];

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [recentMovements, setRecentMovements] = useState<unknown[]>([]);
  const [missingAssets, setMissingAssets] = useState<Asset[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.get("/dashboard"),
      api.get("/dashboard/recent-movements"),
      api.get("/assets", { params: { status: "missing" } }),
    ])
      .then(([statsRes, movementsRes, missingRes]) => {
        setStats(statsRes.data);
        setRecentMovements(movementsRes.data);
        setMissingAssets(missingRes.data);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading dashboard...</div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Admin Dashboard</h1>
        <Link
          href="/scan"
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm font-medium"
        >
          📷 Scan QR Code
        </Link>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        {statCards.map((card) => (
          <div
            key={card.key}
            className="bg-white rounded-xl shadow-sm border p-5"
          >
            <div className="flex items-center justify-between mb-2">
              <div className={`w-2.5 h-2.5 rounded-full ${card.color}`} />
              <span className="text-xl">{card.icon}</span>
            </div>
            <p className="text-3xl font-bold">
              {stats ? (stats as Record<string, number>)[card.key] ?? 0 : 0}
            </p>
            <p className="text-sm text-gray-500 mt-1">{card.label}</p>
          </div>
        ))}
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl shadow-sm border p-5">
          <h2 className="font-bold mb-4">Recently Moved Assets</h2>
          {recentMovements.length === 0 ? (
            <p className="text-gray-400 text-sm">No recent movements</p>
          ) : (
            <div className="space-y-2">
              {(recentMovements as { id: number; asset_id: number; action: string; created_at: string; purpose: string | null }[]).slice(0, 8).map(
                (m) => (
                  <div key={m.id} className="flex items-center justify-between text-sm border-b pb-2">
                    <div>
                      <span className="font-medium">{m.action}</span>
                      <span className="text-gray-400 ml-2">Asset #{m.asset_id}</span>
                    </div>
                    <span className="text-gray-400 text-xs">
                      {new Date(m.created_at).toLocaleString()}
                    </span>
                  </div>
                )
              )}
            </div>
          )}
        </div>

        <div className="bg-white rounded-xl shadow-sm border p-5">
          <h2 className="font-bold mb-4 text-red-700">Missing Assets</h2>
          {missingAssets.length === 0 ? (
            <p className="text-green-600 text-sm">No missing assets</p>
          ) : (
            <div className="space-y-2">
              {missingAssets.map((asset) => (
                <div key={asset.id} className="flex items-center justify-between text-sm border-b pb-2">
                  <div>
                    <span className="font-mono font-medium">{asset.asset_id}</span>
                    <span className="text-gray-500 ml-2">{asset.name}</span>
                  </div>
                  <span className="text-gray-400 text-xs">
                    Last known: {asset.current_user?.name || asset.current_location?.name || "Unknown"}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
