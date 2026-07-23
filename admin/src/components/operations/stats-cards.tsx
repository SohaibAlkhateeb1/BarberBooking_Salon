"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Headphones, KeyRound, ShieldCheck, Megaphone, AlertTriangle } from "lucide-react";

interface StatsData {
  pendingActions: {
    tickets: number;
    passwordResets: number;
    verifications: number;
    complaints: number;
    total: number;
  };
  alerts: {
    new: number;
    critical: number;
    total: number;
  };
}

const stats = [
  { key: "tickets", label: "تذاكر الدعم", icon: Headphones, color: "text-blue-600", bg: "bg-blue-50" },
  { key: "passwordResets", label: "إعادة كلمة المرور", icon: KeyRound, color: "text-purple-600", bg: "bg-purple-50" },
  { key: "verifications", label: "التحقق من الهاتف", icon: ShieldCheck, color: "text-emerald-600", bg: "bg-emerald-50" },
  { key: "complaints", label: "الشكاوى", icon: Megaphone, color: "text-orange-600", bg: "bg-orange-50" },
  { key: "alerts", label: "التنبيهات", icon: AlertTriangle, color: "text-red-600", bg: "bg-red-50" },
];

export function OperationStatsCards({ data, activeTab, onTabChange }: { data: StatsData | null; activeTab: string; onTabChange: (tab: string) => void }) {
  if (!data) return null;

  const getCount = (key: string) => {
    if (key === "alerts") return data.alerts.total;
    return (data.pendingActions as any)[key] || 0;
  };

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
      {stats.map((s) => {
        const count = getCount(s.key);
        const isActive = activeTab === s.key;
        return (
          <Card
            key={s.key}
            className={`cursor-pointer transition-all hover:shadow-md ${isActive ? "ring-2 ring-primary" : ""}`}
            onClick={() => onTabChange(s.key)}
          >
            <CardContent className="p-4 flex items-center gap-3">
              <div className={`p-2 rounded-lg ${s.bg}`}>
                <s.icon className={`size-5 ${s.color}`} />
              </div>
              <div>
                <p className="text-2xl font-bold">{count}</p>
                <p className="text-xs text-muted-foreground">{s.label}</p>
              </div>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
}
