"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useAuth } from "@/lib/auth-context";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import { LayoutDashboard, Users, Scissors, Calendar, CreditCard, Banknote, LogOut, ClipboardList, Bell } from "lucide-react";
import { getOperationsCounts, OperationsCounts } from "@/lib/api";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/dashboard/barbers", label: "Barbers", icon: Scissors },
  { href: "/dashboard/customers", label: "Customers", icon: Users },
  { href: "/dashboard/bookings", label: "Bookings", icon: Calendar },
  { href: "/dashboard/subscriptions", label: "Subscriptions", icon: CreditCard },
  { href: "/dashboard/payments", label: "Payment Requests", icon: Banknote, badgeKey: "payments" as const },
  { href: "/dashboard/operations", label: "Operations Center", icon: ClipboardList, badgeKey: "pendingActions" as const },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, fullName, logout, token: authToken } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [counts, setCounts] = useState<OperationsCounts | null>(null);
  const [showNotifications, setShowNotifications] = useState(false);
  const [hasNewNotification, setHasNewNotification] = useState(false);

  const fetchNotifications = useCallback(async () => {
    if (!authToken) return;
    try {
      const data = await getOperationsCounts(authToken);
      const prev = counts;
      setCounts(data);

      // Flash when new notifications arrive
      if (prev && data.unreadNotifications > prev.unreadNotifications) {
        setHasNewNotification(true);
        setTimeout(() => setHasNewNotification(false), 3000);
      }
    } catch {}
  }, [authToken, counts]);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push("/login");
    }
  }, [isAuthenticated, router]);

  useEffect(() => {
    fetchNotifications();
    const interval = setInterval(fetchNotifications, 15000);
    return () => clearInterval(interval);
  }, [fetchNotifications]);

  if (!isAuthenticated) {
    return null;
  }

  const getBadgeCount = (badgeKey?: string): number => {
    if (!counts || !badgeKey) return 0;
    if (badgeKey === "pendingActions") return counts.pendingActions.total;
    if (badgeKey === "subscriptions") return counts.subscriptions.total;
    if (badgeKey === "payments") return counts.payments.pending;
    return 0;
  };

  const getBadgeColor = (badgeKey?: string): string => {
    if (!badgeKey) return "bg-red-500";
    if (badgeKey === "subscriptions") return "bg-amber-500";
    if (badgeKey === "payments") return "bg-emerald-500";
    return "bg-red-500";
  };

  const totalBellCount = (counts?.unreadNotifications ?? 0);

  return (
    <div className="flex min-h-screen">
      <aside className="w-64 border-r bg-muted/30 flex flex-col">
        <div className="p-4 border-b flex items-center justify-between">
          <div>
            <h1 className="text-lg font-bold">BarberBooking</h1>
            <p className="text-xs text-muted-foreground">Admin Dashboard</p>
          </div>
          <div className="relative">
            <button
              onClick={() => setShowNotifications(!showNotifications)}
              className="relative p-2 rounded-lg hover:bg-muted transition-colors"
            >
              <Bell className={`size-5 transition-colors ${hasNewNotification ? "text-amber-500" : "text-muted-foreground"}`} />
              {totalBellCount > 0 && (
                <span className="absolute -top-1 -right-1 bg-red-500 text-white text-[10px] font-bold rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1 animate-pulse">
                  {totalBellCount > 99 ? "99+" : totalBellCount}
                </span>
              )}
            </button>

            {showNotifications && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setShowNotifications(false)} />
                <div className="absolute left-0 top-full mt-2 w-72 bg-card border rounded-xl shadow-xl z-50 overflow-hidden">
                  <div className="p-3 border-b bg-muted/50">
                    <p className="text-sm font-bold">الإشعارات</p>
                  </div>
                  <div className="max-h-80 overflow-y-auto divide-y">
                    {counts?.payments.pending ? (
                      <Link
                        href="/dashboard/payments"
                        onClick={() => setShowNotifications(false)}
                        className="flex items-center gap-3 p-3 hover:bg-muted/50 transition-colors"
                      >
                        <div className="size-8 rounded-full bg-emerald-500/10 flex items-center justify-center">
                          <Banknote className="size-4 text-emerald-500" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium truncate">طلبات دفع معلقة</p>
                          <p className="text-xs text-muted-foreground">{counts.payments.pending} طلب بانتظار المراجعة</p>
                        </div>
                        <span className="bg-emerald-500 text-white text-xs font-bold rounded-full px-2 py-0.5">
                          {counts.payments.pending}
                        </span>
                      </Link>
                    ) : null}

                    {counts?.pendingActions.total ? (
                      <Link
                        href="/dashboard/operations"
                        onClick={() => setShowNotifications(false)}
                        className="flex items-center gap-3 p-3 hover:bg-muted/50 transition-colors"
                      >
                        <div className="size-8 rounded-full bg-red-500/10 flex items-center justify-center">
                          <ClipboardList className="size-4 text-red-500" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium truncate">عمليات تحتاج مراجعة</p>
                          <p className="text-xs text-muted-foreground">{counts.pendingActions.total} عنصر بانتظار المراجعة</p>
                        </div>
                        <span className="bg-red-500 text-white text-xs font-bold rounded-full px-2 py-0.5">
                          {counts.pendingActions.total}
                        </span>
                      </Link>
                    ) : null}

                    {!counts?.payments.pending && !counts?.pendingActions.total && (
                      <div className="p-6 text-center text-sm text-muted-foreground">
                        لا توجد إشعارات جديدة
                      </div>
                    )}
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
        <nav className="flex-1 p-2 space-y-1">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            const badgeCount = getBadgeCount(item.badgeKey);
            const showBadge = badgeCount > 0;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 rounded-md px-3 py-2 text-sm transition-colors ${
                  isActive
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:bg-muted hover:text-foreground"
                }`}
              >
                <item.icon className="size-4" />
                <span className="flex-1">{item.label}</span>
                {showBadge && (
                  <span className={`${getBadgeColor(item.badgeKey)} text-white text-xs font-bold rounded-full px-2 py-0.5 min-w-[20px] text-center`}>
                    {badgeCount > 99 ? "99+" : badgeCount}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>
        <div className="p-4 border-t">
          <p className="text-sm font-medium truncate">{fullName}</p>
          <Button
            variant="ghost"
            size="sm"
            className="w-full justify-start mt-1"
            onClick={() => {
              logout();
              router.push("/login");
            }}
          >
            <LogOut className="size-4 mr-2" />
            Logout
          </Button>
        </div>
      </aside>
      <main className="flex-1 overflow-auto p-6">{children}</main>
    </div>
  );
}
