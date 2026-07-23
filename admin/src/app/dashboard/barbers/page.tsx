"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { getBarbers, toggleBarberActive, type Barber } from "@/lib/api";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function BarbersPage() {
  const { token } = useAuth();
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [toggling, setToggling] = useState<string | null>(null);

  const loadBarbers = async (p: number) => {
    if (!token) return;
    setLoading(true);
    try {
      const res = await getBarbers(token, p);
      setBarbers(res.barbers);
      setTotalCount(res.totalCount);
    } catch {
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBarbers(page);
  }, [token, page]);

  const handleToggle = async (id: string) => {
    if (!token) return;
    setToggling(id);
    try {
      await toggleBarberActive(token, id);
      loadBarbers(page);
    } catch {
    } finally {
      setToggling(null);
    }
  };

  const totalPages = Math.ceil(totalCount / 20);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Barbers Management</h1>
      <p className="text-sm text-muted-foreground">Total: {totalCount} barbers</p>

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Shop Name</TableHead>
                <TableHead>Owner</TableHead>
                <TableHead>Phone</TableHead>
                <TableHead>City</TableHead>
                <TableHead>Rating</TableHead>
                <TableHead>Plan</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {barbers.map((b) => (
                <TableRow key={b.id}>
                  <TableCell className="font-medium">{b.shopName}</TableCell>
                  <TableCell>{b.ownerName}</TableCell>
                  <TableCell>{b.phoneNumber}</TableCell>
                  <TableCell>{b.city}</TableCell>
                  <TableCell>{b.averageRating > 0 ? `${b.averageRating} (${b.reviewCount})` : "New"}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{b.subscriptionPlan || "None"}</Badge>
                  </TableCell>
                  <TableCell>
                    <Badge variant={b.isUserActive ? "default" : "destructive"}>
                      {b.isUserActive ? "Active" : "Inactive"}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="sm"
                      disabled={toggling === b.id}
                      onClick={() => handleToggle(b.id)}
                    >
                      {toggling === b.id ? "..." : b.isUserActive ? "Deactivate" : "Activate"}
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {barbers.length === 0 && !loading && (
                <TableRow>
                  <TableCell colSpan={8} className="text-center text-muted-foreground">No barbers found</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

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
