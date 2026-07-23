"use client";

import { Badge } from "@/components/ui/badge";

const roleConfig: Record<string, { label: string; className: string; emoji: string }> = {
  Customer: { label: "زبون", className: "bg-sky-100 text-sky-800 border-sky-300", emoji: "🟢" },
  Barber: { label: "حلاق", className: "bg-emerald-100 text-emerald-800 border-emerald-300", emoji: "🔵" },
  Admin: { label: "أدمن", className: "bg-red-100 text-red-800 border-red-300", emoji: "🔴" },
  System: { label: "النظام", className: "bg-gray-100 text-gray-800 border-gray-300", emoji: "⚙️" },
};

export function UserBadge({ role, plan }: { role: string; plan?: string }) {
  const config = roleConfig[role] || { label: role, className: "", emoji: "" };

  if (role === "Barber" && plan) {
    const planLabel = plan.toLowerCase().includes("premium") ? "VIP" :
                      plan.toLowerCase().includes("pro") ? "Pro" : "Basic";
    const planColor = planLabel === "VIP" ? "bg-purple-500" :
                      planLabel === "Pro" ? "bg-blue-500" : "bg-gray-500";
    return (
      <div className="flex items-center gap-1">
        <Badge className={config.className}>{config.emoji} {config.label}</Badge>
        <Badge className={`${planColor} text-white text-xs`}>{planLabel}</Badge>
      </div>
    );
  }

  return <Badge className={config.className}>{config.emoji} {config.label}</Badge>;
}
