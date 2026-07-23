"use client";

import { Badge } from "@/components/ui/badge";

const priorityConfig: Record<string, { label: string; className: string }> = {
  Low: { label: "منخفضة", className: "bg-gray-100 text-gray-800 border-gray-300" },
  Medium: { label: "متوسطة", className: "bg-blue-100 text-blue-800 border-blue-300" },
  High: { label: "عالية", className: "bg-orange-100 text-orange-800 border-orange-300" },
  Critical: { label: "عاجلة", className: "bg-red-500 hover:bg-red-600 text-white" },
  Urgent: { label: "عاجلة", className: "bg-red-500 hover:bg-red-600 text-white" },
  Normal: { label: "عادية", className: "bg-green-100 text-green-800 border-green-300" },
};

export function PriorityBadge({ priority }: { priority: string }) {
  const config = priorityConfig[priority] || { label: priority, className: "" };
  return <Badge className={config.className}>{config.label}</Badge>;
}
