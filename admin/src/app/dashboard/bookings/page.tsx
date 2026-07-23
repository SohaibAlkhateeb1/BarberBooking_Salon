"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { getBookings, type Booking } from "@/lib/api";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

const statusFilters = ["", "Upcoming", "Completed", "Cancelled"];

export default function BookingsPage() {
  const { token } = useAuth();
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState("");
  const [loading, setLoading] = useState(true);

  const loadBookings = async (p: number) => {
    if (!token) return;
    setLoading(true);
    try {
      const res = await getBookings(token, p, statusFilter || undefined);
      setBookings(res.bookings);
      setTotalCount(res.totalCount);
    } catch {
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    setPage(1);
    loadBookings(1);
  }, [token, statusFilter]);

  useEffect(() => {
    loadBookings(page);
  }, [page]);

  const totalPages = Math.ceil(totalCount / 20);

  const badgeVariant = (status: string) => {
    switch (status) {
      case "Completed": return "default";
      case "Cancelled": return "destructive";
      case "Upcoming": return "secondary";
      default: return "outline";
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Bookings</h1>
          <p className="text-sm text-muted-foreground">Total: {totalCount} bookings</p>
        </div>
        <div className="flex gap-1">
          {statusFilters.map((s) => (
            <Button
              key={s || "all"}
              variant={statusFilter === s ? "default" : "outline"}
              size="sm"
              onClick={() => setStatusFilter(s)}
            >
              {s || "All"}
            </Button>
          ))}
        </div>
      </div>

      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Customer</TableHead>
              <TableHead>Shop</TableHead>
              <TableHead>Service</TableHead>
              <TableHead>Date</TableHead>
              <TableHead>Price</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Payment</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {bookings.map((b) => (
              <TableRow key={b.id}>
                <TableCell>
                  <p className="font-medium">{b.customerName}</p>
                  <p className="text-xs text-muted-foreground">{b.customerPhone}</p>
                </TableCell>
                <TableCell>{b.shopName}</TableCell>
                <TableCell>{b.serviceName}</TableCell>
                <TableCell>{new Date(b.bookingDate).toLocaleDateString()}</TableCell>
                <TableCell>₪{b.finalPrice}</TableCell>
                <TableCell>
                  <Badge variant={badgeVariant(b.status)}>{b.status}</Badge>
                </TableCell>
                <TableCell>
                  <Badge variant={b.paymentStatus === "Paid" ? "default" : "outline"}>
                    {b.paymentStatus} ({b.paymentMethod || "cash"})
                  </Badge>
                </TableCell>
              </TableRow>
            ))}
            {bookings.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={7} className="text-center text-muted-foreground">No bookings found</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {totalPages > 1 && (
        <div className="flex justify-center gap-2">
          <Button variant="outline" size="sm" disabled={page === 1} onClick={() => setPage(page - 1)}>
            Previous
          </Button>
          <span className="flex items-center px-3 text-sm">
            Page {page} of {totalPages}
          </span>
          <Button variant="outline" size="sm" disabled={page === totalPages} onClick={() => setPage(page + 1)}>
            Next
          </Button>
        </div>
      )}
    </div>
  );
}
