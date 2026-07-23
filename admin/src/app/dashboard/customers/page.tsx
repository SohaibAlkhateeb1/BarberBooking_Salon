"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { getCustomers, unblockCustomer, type Customer } from "@/lib/api";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

export default function CustomersPage() {
  const { token } = useAuth();
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);

  const loadCustomers = async (p: number) => {
    if (!token) return;
    setLoading(true);
    try {
      const res = await getCustomers(token, p);
      setCustomers(res.customers);
      setTotalCount(res.totalCount);
    } catch {
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCustomers(page);
  }, [token, page]);

  const handleUnblock = async (id: string) => {
    if (!token) return;
    try {
      await unblockCustomer(token, id);
      loadCustomers(page);
    } catch {}
  };

  const totalPages = Math.ceil(totalCount / 20);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Customers Management</h1>
      <p className="text-sm text-muted-foreground">Total: {totalCount} customers</p>

      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Phone</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>City</TableHead>
              <TableHead>Bookings</TableHead>
              <TableHead>No Shows</TableHead>
              <TableHead>Cancels Today</TableHead>
              <TableHead>Blocked</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Joined</TableHead>
              <TableHead>Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {customers.map((c) => (
              <TableRow key={c.id}>
                <TableCell className="font-medium">{c.fullName}</TableCell>
                <TableCell>{c.phoneNumber}</TableCell>
                <TableCell>{c.email || "-"}</TableCell>
                <TableCell>{c.city || "-"}</TableCell>
                <TableCell>{c.totalBookings || 0}</TableCell>
                <TableCell>
                  {c.noShowCount > 0 ? (
                    <Badge variant={c.noShowCount >= 2 ? "destructive" : "secondary"}>
                      {c.noShowCount}
                    </Badge>
                  ) : (
                    <span className="text-muted-foreground">0</span>
                  )}
                </TableCell>
                <TableCell>
                  {c.dailyCancelCount > 0 ? (
                    <Badge variant={c.dailyCancelCount >= 2 ? "destructive" : "secondary"}>
                      {c.dailyCancelCount}
                    </Badge>
                  ) : (
                    <span className="text-muted-foreground">0</span>
                  )}
                </TableCell>
                <TableCell>
                  {c.isBookingBlocked ? (
                    <Badge variant="destructive">
                      Blocked
                      {c.blockReason && ` - ${c.blockReason}`}
                    </Badge>
                  ) : (
                    <span className="text-muted-foreground">No</span>
                  )}
                </TableCell>
                <TableCell>
                  <Badge variant={c.isActive ? "default" : "destructive"}>
                    {c.isActive ? "Active" : "Inactive"}
                  </Badge>
                </TableCell>
                <TableCell>{new Date(c.createdAt).toLocaleDateString()}</TableCell>
                <TableCell>
                  {c.isBookingBlocked && (
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleUnblock(c.id)}
                    >
                      Unblock
                    </Button>
                  )}
                </TableCell>
              </TableRow>
            ))}
            {customers.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={11} className="text-center text-muted-foreground">No customers found</TableCell>
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
