"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { getDashboard, type DashboardStats } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Users, Scissors, Calendar, DollarSign, TrendingUp } from "lucide-react";

export default function DashboardPage() {
  const { token } = useAuth();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!token) return;
    setLoading(true);
    getDashboard(token)
      .then(setStats)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [token]);

  if (loading) return <p className="text-muted-foreground">Loading dashboard...</p>;
  if (error) return <p className="text-destructive">Error: {error}</p>;
  if (!stats) return null;

  const statCards = [
    { title: "Total Barbers", value: stats.totalBarbers, icon: Scissors },
    { title: "Total Customers", value: stats.totalCustomers, icon: Users },
    { title: "Total Bookings", value: stats.totalBookings, icon: Calendar },
    { title: "Total Revenue", value: `₪${stats.totalRevenue.toLocaleString()}`, icon: DollarSign },
    { title: "Active Bookings", value: stats.activeBookings, icon: TrendingUp },
    { title: "Today Bookings", value: stats.todayBookings, icon: Calendar },
    { title: "Monthly Revenue", value: `₪${stats.monthlyRevenue.toLocaleString()}`, icon: DollarSign },
    { title: "Active Subscriptions", value: stats.activeSubscriptions, icon: TrendingUp },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Dashboard</h1>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((c) => (
          <Card key={c.title}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">{c.title}</CardTitle>
              <c.icon className="size-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">{c.value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Top Barbers</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Shop</TableHead>
                  <TableHead>Bookings</TableHead>
                  <TableHead>Revenue</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {stats.topBarbers.map((b, i) => (
                  <TableRow key={i}>
                    <TableCell>
                      <p className="font-medium">{b.shopName}</p>
                      <p className="text-xs text-muted-foreground">{b.barberName}</p>
                    </TableCell>
                    <TableCell>{b.bookingCount}</TableCell>
                    <TableCell>₪{b.revenue.toLocaleString()}</TableCell>
                  </TableRow>
                ))}
                {stats.topBarbers.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={3} className="text-center text-muted-foreground">No data yet</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Recent Bookings</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Customer</TableHead>
                  <TableHead>Service</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Price</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {stats.recentBookings.map((b) => (
                  <TableRow key={b.id}>
                    <TableCell>{b.customerName}</TableCell>
                    <TableCell>{b.serviceName}</TableCell>
                    <TableCell>
                      <Badge variant={b.status === "Completed" ? "default" : b.status === "Cancelled" ? "destructive" : "secondary"}>
                        {b.status}
                      </Badge>
                    </TableCell>
                    <TableCell>₪{b.finalPrice}</TableCell>
                  </TableRow>
                ))}
                {stats.recentBookings.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={4} className="text-center text-muted-foreground">No bookings yet</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      {stats.cityStats.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Barbers by City</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-3">
              {stats.cityStats.map((c, i) => (
                <Badge key={i} variant="secondary" className="text-sm">
                  {c.city}: {c.count}
                </Badge>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
