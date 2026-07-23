"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  getSubscriptions,
  getSubscriptionStats,
  extendSubscription,
  Subscription,
  SubscriptionStats,
} from "@/lib/api";
import { CreditCard, TrendingUp, Users, AlertTriangle } from "lucide-react";

export default function SubscriptionsPage() {
  const { token } = useAuth();
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [stats, setStats] = useState<SubscriptionStats | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [loading, setLoading] = useState(true);
  const [extendDialogOpen, setExtendDialogOpen] = useState(false);
  const [selectedSubscription, setSelectedSubscription] = useState<Subscription | null>(null);
  const [extendDays, setExtendDays] = useState(30);

  useEffect(() => {
    if (token) {
      loadData();
    }
  }, [token, statusFilter]);

  async function loadData() {
    if (!token) return;
    setLoading(true);
    try {
      const [subs, statsData] = await Promise.all([
        getSubscriptions(token, statusFilter === "all" ? undefined : statusFilter),
        getSubscriptionStats(token),
      ]);
      setSubscriptions(subs);
      setStats(statsData);
    } catch (error) {
      console.error("Failed to load subscriptions:", error);
    } finally {
      setLoading(false);
    }
  }

  async function handleExtend() {
    if (!token || !selectedSubscription) return;
    try {
      await extendSubscription(token, selectedSubscription.subscriptionId, extendDays);
      setExtendDialogOpen(false);
      setSelectedSubscription(null);
      loadData();
    } catch (error) {
      console.error("Failed to extend subscription:", error);
    }
  }

  function getStatusBadge(status: string) {
    switch (status) {
      case "active":
        return <Badge className="bg-green-100 text-green-800">Active</Badge>;
      case "expired":
        return <Badge className="bg-yellow-100 text-yellow-800">Expired</Badge>;
      case "cancelled":
        return <Badge className="bg-red-100 text-red-800">Cancelled</Badge>;
      case "cancel_pending":
        return <Badge className="bg-orange-100 text-orange-800">Cancel Pending</Badge>;
      default:
        return <Badge>{status}</Badge>;
    }
  }

  function getPlanBadge(planName: string) {
    switch (planName.toLowerCase()) {
      case "basic":
        return <Badge className="bg-gray-100 text-gray-800">Basic</Badge>;
      case "pro":
        return <Badge className="bg-blue-100 text-blue-800">Pro</Badge>;
      case "premium":
        return <Badge className="bg-purple-100 text-purple-800">VIP</Badge>;
      default:
        return <Badge>{planName}</Badge>;
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Subscriptions</h1>
        <p className="text-muted-foreground">Manage barber subscriptions and plans</p>
      </div>

      {/* Stats Cards */}
      {stats && (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Active Subscriptions</CardTitle>
              <CreditCard className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalActiveSubscriptions}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Monthly Revenue</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalMonthlyRevenue.toLocaleString()} ₪</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">New This Month</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.newThisMonth}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Expired This Month</CardTitle>
              <AlertTriangle className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.expiredThisMonth}</div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Plan Distribution */}
      {stats && (
        <div className="grid gap-4 md:grid-cols-3">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Basic Plan</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalBasicSubscriptions}</div>
              <p className="text-xs text-muted-foreground">80₪/month</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Pro Plan</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalProSubscriptions}</div>
              <p className="text-xs text-muted-foreground">100₪/month</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">VIP Plan</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalPremiumSubscriptions}</div>
              <p className="text-xs text-muted-foreground">150₪/month</p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Filters */}
      <div className="flex items-center gap-4">
        <Select value={statusFilter} onValueChange={(value) => setStatusFilter(value || "all")}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Filter by status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="active">Active</SelectItem>
            <SelectItem value="cancel_pending">Cancel Pending</SelectItem>
            <SelectItem value="expired">Expired</SelectItem>
            <SelectItem value="cancelled">Cancelled</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Subscriptions Table */}
      <Card>
        <CardHeader>
          <CardTitle>Subscriptions</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-4">Loading...</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>المشترك</TableHead>
                  <TableHead>Plan</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Period</TableHead>
                  <TableHead>Start Date</TableHead>
                  <TableHead>End Date</TableHead>
                  <TableHead>Days Left</TableHead>
                  <TableHead>Bookings</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {subscriptions.map((sub) => (
                  <TableRow key={sub.subscriptionId}>
                    <TableCell>
                      <div className="font-medium">{sub.ownerName}</div>
                      <div className="text-xs text-muted-foreground">{sub.shopName}</div>
                    </TableCell>
                    <TableCell>{getPlanBadge(sub.planName)}</TableCell>
                    <TableCell>{getStatusBadge(sub.status)}</TableCell>
                    <TableCell>{sub.amountPaid.toLocaleString()} ₪</TableCell>
                    <TableCell>{sub.isYearly ? "Yearly" : "Monthly"}</TableCell>
                    <TableCell>{new Date(sub.startDate).toLocaleDateString()}</TableCell>
                    <TableCell>{new Date(sub.endDate).toLocaleDateString()}</TableCell>
                    <TableCell>
                      <span className={sub.daysRemaining <= 7 ? "text-red-600 font-medium" : ""}>
                        {sub.daysRemaining} days
                      </span>
                    </TableCell>
                    <TableCell>{sub.currentBookingsCount}/{sub.maxBookingsPerMonth === -1 ? "∞" : sub.maxBookingsPerMonth}</TableCell>
                    <TableCell>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => {
                          setSelectedSubscription(sub);
                          setExtendDialogOpen(true);
                        }}
                      >
                        Extend
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Extend Modal */}
      {extendDialogOpen && selectedSubscription && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h2 className="text-lg font-bold mb-4">Extend Subscription</h2>
            <div className="space-y-4">
              <div>
                <Label>Current Plan</Label>
                <p className="text-sm">{selectedSubscription.planNameArabic}</p>
              </div>
              <div>
                <Label>End Date</Label>
                <p className="text-sm">{new Date(selectedSubscription.endDate).toLocaleDateString()}</p>
              </div>
              <div>
                <Label>Extend by (days)</Label>
                <Input
                  type="number"
                  value={extendDays}
                  onChange={(e) => setExtendDays(parseInt(e.target.value) || 0)}
                  min={1}
                  max={365}
                />
              </div>
              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setExtendDialogOpen(false)}>
                  Cancel
                </Button>
                <Button onClick={handleExtend}>Extend</Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
