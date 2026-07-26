"use client";

import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useAuth } from "@/lib/auth-context";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import { LayoutDashboard, Users, Scissors, Calendar, CreditCard, Banknote, LogOut, ClipboardList, Bell } from "lucide-react";

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
  const { isAuthenticated, fullName, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (!isAuthenticated) {
      router.push("/login");
    }
  }, [isAuthenticated, router]);

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="flex min-h-screen">
      <aside className="w-64 border-r bg-muted/30 flex flex-col">
        <div className="p-4 border-b flex items-center justify-between">
          <div>
            <h1 className="text-lg font-bold">BarberBooking</h1>
            <p className="text-xs text-muted-foreground">Admin Dashboard</p>
          </div>
          <button
            onClick={() => router.push("/dashboard/operations")}
            className="relative p-2 rounded-lg hover:bg-muted transition-colors"
          >
            <Bell className="size-5 text-muted-foreground" />
          </button>
        </div>
        <nav className="flex-1 p-2 space-y-1">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
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
