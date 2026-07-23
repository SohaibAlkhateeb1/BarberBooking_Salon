"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { getAuditLog, type AuditLogEntry } from "@/lib/api";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { ChevronLeft, ChevronRight } from "lucide-react";

export function AuditLogTable({
  actionFilter,
  entityFilter,
}: {
  actionFilter?: string;
  entityFilter?: string;
}) {
  const { token } = useAuth();
  const [logs, setLogs] = useState<AuditLogEntry[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const pageSize = 15;

  useEffect(() => {
    if (!token) return;
    setLoading(true);
    getAuditLog(token, { action: actionFilter, entityType: entityFilter, page })
      .then((data) => {
        setLogs(data.logs);
        setTotalCount(data.totalCount);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [token, actionFilter, entityFilter, page]);

  const totalPages = Math.ceil(totalCount / pageSize);

  if (loading) return <div className="text-center py-8 text-muted-foreground">جاري تحميل السجل...</div>;

  if (logs.length === 0) return <div className="text-center py-8 text-muted-foreground">لا يوجد سجل</div>;

  const actionColors: Record<string, string> = {
    SendOtp: "text-green-600",
    RejectVerification: "text-red-600",
    MarkRead: "text-blue-600",
    ResetPassword: "text-purple-600",
    CreateAlert: "text-orange-600",
  };

  return (
    <div className="space-y-3">
      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>التاريخ</TableHead>
              <TableHead>الإجراء</TableHead>
              <TableHead>النوع</TableHead>
              <TableHead>المعرف</TableHead>
              <TableHead>الأدمن</TableHead>
              <TableHead>التفاصيل</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {logs.map((log) => (
              <TableRow key={log.id}>
                <TableCell className="text-xs whitespace-nowrap">
                  {new Date(log.createdAt).toLocaleString("ar-EG")}
                </TableCell>
                <TableCell>
                  <span className={`text-sm font-medium ${actionColors[log.action] || ""}`}>
                    {log.action}
                  </span>
                </TableCell>
                <TableCell className="text-sm">{log.entityType}</TableCell>
                <TableCell className="font-mono text-xs max-w-[120px] truncate">{log.entityId}</TableCell>
                <TableCell className="text-sm">{log.adminName}</TableCell>
                <TableCell className="text-xs max-w-[200px] truncate text-muted-foreground">
                  {log.details || "—"}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">
            صفحة {page} من {totalPages} ({totalCount} سجل)
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page === 1}
              onClick={() => setPage((p) => p - 1)}
            >
              <ChevronRight className="size-4" />
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page === totalPages}
              onClick={() => setPage((p) => p + 1)}
            >
              <ChevronLeft className="size-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
