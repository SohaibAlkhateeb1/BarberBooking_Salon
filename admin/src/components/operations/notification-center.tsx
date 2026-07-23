"use client";

import { useEffect, useState, useCallback } from "react";
import { useAuth } from "@/lib/auth-context";
import { getRecentActivity, type RecentActivity } from "@/lib/api";
import { Bell } from "lucide-react";
import { Button } from "@/components/ui/button";

export function NotificationCenter({ unreadCount }: { unreadCount: number }) {
  const { token } = useAuth();
  const [activities, setActivities] = useState<RecentActivity[]>([]);
  const [open, setOpen] = useState(false);

  const fetchActivities = useCallback(async () => {
    if (!token) return;
    try {
      const data = await getRecentActivity(token);
      setActivities(data);
    } catch {}
  }, [token]);

  useEffect(() => {
    fetchActivities();
    const interval = setInterval(fetchActivities, 30000);
    return () => clearInterval(interval);
  }, [fetchActivities]);

  const colorMap: Record<string, string> = {
    red: "bg-red-500",
    orange: "bg-orange-500",
    blue: "bg-blue-500",
    green: "bg-green-500",
    purple: "bg-purple-500",
    gray: "bg-gray-400",
  };

  return (
    <div className="relative">
      <Button variant="ghost" size="icon" className="relative" onClick={() => setOpen(!open)}>
        <Bell className="size-5" />
        {unreadCount > 0 && (
          <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">
            {unreadCount > 99 ? "99+" : unreadCount}
          </span>
        )}
      </Button>

      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute left-0 top-full mt-2 w-80 bg-background border rounded-lg shadow-lg z-50 max-h-[400px] overflow-y-auto">
            <div className="p-3 border-b font-medium text-sm">آخر الأحداث</div>
            {activities.length === 0 ? (
              <div className="p-4 text-center text-muted-foreground text-sm">لا توجد أحداث</div>
            ) : (
              activities.map((a, i) => (
                <div key={i} className="p-3 border-b last:border-0 hover:bg-muted/50 transition-colors">
                  <div className="flex items-start gap-2">
                    <div className={`w-2 h-2 rounded-full mt-2 shrink-0 ${colorMap[a.color] || "bg-gray-400"}`} />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium truncate">{a.title}</p>
                      <p className="text-xs text-muted-foreground truncate">{a.subtitle}</p>
                      <p className="text-xs text-muted-foreground mt-0.5">
                        {new Date(a.createdAt).toLocaleString("ar-EG")}
                      </p>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </>
      )}
    </div>
  );
}
