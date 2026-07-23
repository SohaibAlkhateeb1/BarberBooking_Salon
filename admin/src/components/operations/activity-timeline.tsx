"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { getActivityTimeline, type TimelineEvent } from "@/lib/api";
import { format } from "date-fns";
import { ar } from "date-fns/locale";

export function ActivityTimeline({ entityType, entityId }: { entityType: string; entityId: string }) {
  const { token } = useAuth();
  const [events, setEvents] = useState<TimelineEvent[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!token || !entityId) return;
    setLoading(true);
    getActivityTimeline(token, entityType, entityId)
      .then(setEvents)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [token, entityType, entityId]);

  if (loading) return <div className="text-center py-4 text-muted-foreground text-sm">جاري تحميل السجل...</div>;
  if (events.length === 0) return <div className="text-center py-4 text-muted-foreground text-sm">لا يوجد سجل</div>;

  const colorMap: Record<string, string> = {
    blue: "bg-blue-500",
    green: "bg-green-500",
    gray: "bg-gray-400",
    purple: "bg-purple-500",
    red: "bg-red-500",
    orange: "bg-orange-500",
  };

  return (
    <div className="space-y-3">
      {events.map((event, i) => (
        <div key={i} className="flex gap-3">
          <div className="flex flex-col items-center">
            <div className={`w-3 h-3 rounded-full ${colorMap[event.color] || "bg-gray-400"} mt-1.5`} />
            {i < events.length - 1 && <div className="w-0.5 flex-1 bg-border mt-1" />}
          </div>
          <div className="pb-4 flex-1">
            <p className="text-sm">{event.action}</p>
            <div className="flex items-center gap-2 text-xs text-muted-foreground mt-0.5">
              <span>{event.by}</span>
              <span>•</span>
              <span>{format(new Date(event.time), "dd MMM yyyy HH:mm", { locale: ar })}</span>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
