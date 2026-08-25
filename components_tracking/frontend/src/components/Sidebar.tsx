"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const navItems = [
  { href: "/scan", label: "QR Scanner", icon: "📷", highlight: true },
  { href: "/", label: "Dashboard", icon: "📊" },
  { href: "/assets", label: "Assets", icon: "📦" },
  { href: "/employees", label: "Employees", icon: "👥" },
  { href: "/drones", label: "Drones", icon: "🛸" },
  { href: "/locations", label: "Locations", icon: "📍" },
  { href: "/projects", label: "Projects", icon: "📁" },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 bg-gray-900 text-white min-h-screen flex flex-col">
      <div className="p-4 border-b border-gray-700">
        <h1 className="text-lg font-bold">QR Asset Tracker</h1>
        <p className="text-xs text-gray-400">Component Management</p>
      </div>
      <nav className="flex-1 p-2">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={`flex items-center gap-3 px-3 py-2.5 rounded-lg mb-1 text-sm transition-colors ${
              item.highlight
                ? pathname === item.href
                  ? "bg-blue-600 text-white"
                  : "bg-blue-900/50 text-blue-300 hover:bg-blue-800/60 border border-blue-700/50"
                : pathname === item.href
                ? "bg-blue-600 text-white"
                : "text-gray-300 hover:bg-gray-800"
            }`}
          >
            <span className="text-base">{item.icon}</span>
            <span>{item.label}</span>
          </Link>
        ))}
      </nav>
      <div className="p-4 border-t border-gray-700 text-xs text-gray-500">
        QR Asset Tracking v1.0
      </div>
    </aside>
  );
}
