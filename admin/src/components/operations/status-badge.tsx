"use client";

import { Badge } from "@/components/ui/badge";

const statusConfig: Record<string, { label: string; className: string }> = {
  New: { label: "جديد", className: "bg-blue-100 text-blue-800 border-blue-300" },
  Open: { label: "مفتوح", className: "bg-yellow-100 text-yellow-800 border-yellow-300" },
  Viewed: { label: "تمت المشاهدة", className: "bg-gray-100 text-gray-800 border-gray-300" },
  "In Progress": { label: "قيد المراجعة", className: "bg-blue-100 text-blue-800 border-blue-300" },
  Acknowledged: { label: "تم الاعتراف", className: "bg-purple-100 text-purple-800 border-purple-300" },
  "Waiting Customer": { label: "بانتظار الزبون", className: "bg-orange-100 text-orange-800 border-orange-300" },
  Resolved: { label: "تم الحل", className: "bg-green-100 text-green-800 border-green-300" },
  Closed: { label: "مغلق", className: "bg-gray-100 text-gray-800 border-gray-300" },
  Rejected: { label: "مرفوض", className: "bg-red-100 text-red-800 border-red-300" },
  Pending: { label: "قيد الانتظار", className: "bg-yellow-100 text-yellow-800 border-yellow-300" },
  Verified: { label: "تم التحقق", className: "bg-green-100 text-green-800 border-green-300" },
  Completed: { label: "مكتمل", className: "bg-green-100 text-green-800 border-green-300" },
};

export function StatusBadge({ status }: { status: string }) {
  const config = statusConfig[status] || { label: status, className: "" };
  return <Badge className={config.className}>{config.label}</Badge>;
}
