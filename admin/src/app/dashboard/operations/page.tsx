"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import { useAuth } from "@/lib/auth-context";
import { useSearchParams } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  getOperationsCounts,
  getOperationsTickets,
  getOperationsVerifications,
  verifyCustomerPhoneOps,
  rejectCustomerVerificationOps,
  getOperationsPasswordResets,
  markPasswordResetRead,
  markAllPasswordResetsRead,
  getSystemAlerts,
  createSystemAlert,
  updateSystemAlertStatus,
  deleteSystemAlert,
  getSupportTicketDetail,
  replyToTicket,
  updateTicketStatus,
  getAuditLog,
  type OperationsCounts,
  type SystemAlert,
  type AuditLogEntry,
  type SupportTicket,
} from "@/lib/api";
import { OperationStatsCards } from "@/components/operations/stats-cards";
import { OperationFilters } from "@/components/operations/filters";
import { StatusBadge } from "@/components/operations/status-badge";
import { PriorityBadge } from "@/components/operations/priority-badge";
import { UserBadge } from "@/components/operations/user-badge";
import { OperationDetailCard } from "@/components/operations/operation-detail-card";
import { AuditLogTable } from "@/components/operations/audit-log-table";
import {
  Headphones,
  KeyRound,
  ShieldCheck,
  AlertTriangle,
  ClipboardList,
  Copy,
  CheckCircle,
  Clock,
  User,
  Phone,
  Send,
  Eye,
  Plus,
  Trash2,
  MessageSquare,
  RefreshCw,
} from "lucide-react";

const TABS = [
  { key: "tickets", label: "تذاكر الدعم", icon: Headphones },
  { key: "verifications", label: "التحقق من الهاتف", icon: ShieldCheck },
  { key: "passwordResets", label: "إعادة كلمة المرور", icon: KeyRound },
  { key: "alerts", label: "التنبيهات", icon: AlertTriangle },
  { key: "auditLog", label: "سجل العمليات", icon: ClipboardList },
];

export default function OperationsCenterPage() {
  const { token } = useAuth();
  const searchParams = useSearchParams();
  const initialTab = searchParams.get("tab") || "tickets";
  const [activeTab, setActiveTab] = useState(initialTab);
  const [counts, setCounts] = useState<OperationsCounts | null>(null);

  // Tickets state
  const [tickets, setTickets] = useState<any[]>([]);
  const [ticketStatusFilter, setTicketStatusFilter] = useState("all");
  const [ticketPriorityFilter, setTicketPriorityFilter] = useState("all");
  const [selectedTicket, setSelectedTicket] = useState<any>(null);
  const [ticketDetail, setTicketDetail] = useState<any>(null);
  const [replyText, setReplyText] = useState("");
  const [ticketLoading, setTicketLoading] = useState(false);

  // Verifications state
  const [verifications, setVerifications] = useState<any[]>([]);
  const [verifyStatusFilter, setVerifyStatusFilter] = useState("all");
  const [verifyLoading, setVerifyLoading] = useState(false);
  const [selectedVerify, setSelectedVerify] = useState<any>(null);

  // Password resets state
  const [passwordResets, setPasswordResets] = useState<any[]>([]);
  const [prStatusFilter, setPrStatusFilter] = useState("all");
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [selectedPr, setSelectedPr] = useState<any>(null);

  // Alerts state
  const [alerts, setAlerts] = useState<SystemAlert[]>([]);
  const [alertStatusFilter, setAlertStatusFilter] = useState("all");
  const [alertSeverityFilter, setAlertSeverityFilter] = useState("all");
  const [selectedAlert, setSelectedAlert] = useState<SystemAlert | null>(null);
  const [showCreateAlert, setShowCreateAlert] = useState(false);
  const [newAlert, setNewAlert] = useState({ title: "", message: "", severity: "Medium", category: "Manual", priority: "Medium" });
  const [alertLoading, setAlertLoading] = useState(false);

  // Common
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");
  const [messageType, setMessageType] = useState<"success" | "error">("success");

  const showMessage = useCallback((msg: string, type: "success" | "error" = "success", duration = 3000) => {
    setMessage(msg);
    setMessageType(type);
    setTimeout(() => setMessage(""), duration);
  }, []);

  // ===== DATA FETCHING =====

  const fetchCounts = useCallback(async () => {
    if (!token) return;
    try {
      const data = await getOperationsCounts(token);
      setCounts(data);
    } catch {}
  }, [token]);

  const fetchTickets = useCallback(async () => {
    if (!token) return;
    setTicketLoading(true);
    try {
      const filters: any = {};
      if (ticketStatusFilter && ticketStatusFilter !== "all") filters.status = ticketStatusFilter;
      if (ticketPriorityFilter && ticketPriorityFilter !== "all") filters.priority = ticketPriorityFilter;
      const data = await getOperationsTickets(token, filters);
      setTickets(data);
    } catch {} finally {
      setTicketLoading(false);
    }
  }, [token, ticketStatusFilter, ticketPriorityFilter]);

  const fetchVerifications = useCallback(async () => {
    if (!token) return;
    setVerifyLoading(true);
    try {
      const status = verifyStatusFilter === "all" ? undefined : verifyStatusFilter;
      const data = await getOperationsVerifications(token, status);
      setVerifications(data.customers);
    } catch {} finally {
      setVerifyLoading(false);
    }
  }, [token, verifyStatusFilter]);

  const fetchPasswordResets = useCallback(async () => {
    if (!token) return;
    try {
      const status = prStatusFilter === "all" ? undefined : prStatusFilter;
      const data = await getOperationsPasswordResets(token, status);
      setPasswordResets(data.notifications);
    } catch {}
  }, [token, prStatusFilter]);

  const fetchAlerts = useCallback(async () => {
    if (!token) return;
    setAlertLoading(true);
    try {
      const filters: any = {};
      if (alertStatusFilter && alertStatusFilter !== "all") filters.status = alertStatusFilter;
      if (alertSeverityFilter && alertSeverityFilter !== "all") filters.severity = alertSeverityFilter;
      const data = await getSystemAlerts(token, filters);
      setAlerts(data);
    } catch {} finally {
      setAlertLoading(false);
    }
  }, [token, alertStatusFilter, alertSeverityFilter]);

  useEffect(() => {
    fetchCounts();
    setLoading(false);
  }, [fetchCounts]);

  useEffect(() => {
    if (activeTab === "tickets") fetchTickets();
    else if (activeTab === "verifications") fetchVerifications();
    else if (activeTab === "passwordResets") fetchPasswordResets();
    else if (activeTab === "alerts") fetchAlerts();
  }, [activeTab, fetchTickets, fetchVerifications, fetchPasswordResets, fetchAlerts]);

  // Auto-refresh
  useEffect(() => {
    const interval = setInterval(() => {
      fetchCounts();
      if (activeTab === "tickets") fetchTickets();
      else if (activeTab === "verifications") fetchVerifications();
      else if (activeTab === "passwordResets") fetchPasswordResets();
      else if (activeTab === "alerts") fetchAlerts();
    }, 15000);
    return () => clearInterval(interval);
  }, [activeTab, fetchCounts, fetchTickets, fetchVerifications, fetchPasswordResets, fetchAlerts]);

  // ===== TICKET HANDLERS =====

  const handleViewTicket = async (ticket: any) => {
    if (!token) return;
    setSelectedTicket(ticket);
    try {
      const detail = await getSupportTicketDetail(token, ticket.id);
      setTicketDetail(detail);
    } catch {}
  };

  const handleReply = async (ticketId: string) => {
    if (!token || !replyText.trim()) return;
    try {
      const updated = await replyToTicket(token, ticketId, replyText.trim());
      setTicketDetail(updated);
      setReplyText("");
      showMessage("تم الإرسال بنجاح");
    } catch (e: any) {
      showMessage(e.message || "خطأ", "error");
    }
  };

  const handleUpdateStatus = async (ticketId: string, status: string) => {
    if (!token) return;
    try {
      await updateTicketStatus(token, ticketId, status);
      showMessage("تم التحديث");
      fetchTickets();
    } catch (e: any) {
      showMessage(e.message || "خطأ", "error");
    }
  };

  // ===== VERIFICATION HANDLERS =====

  const handleVerifyPhone = async (id: string) => {
    if (!token) return;
    try {
      const result = await verifyCustomerPhoneOps(token, id);
      showMessage(`تم توليد الكود: ${result.code} — انسخه وأرسله للزبون عبر واتساب`, "success", 15000);
      fetchVerifications();
      fetchCounts();
    } catch (e: any) {
      showMessage(e.message || "خطأ", "error");
    }
  };

  const handleRejectVerification = async (id: string) => {
    if (!token) return;
    try {
      await rejectCustomerVerificationOps(token, id);
      showMessage("تم الرفض");
      fetchVerifications();
      fetchCounts();
    } catch (e: any) {
      showMessage(e.message || "خطأ", "error");
    }
  };

  // ===== PASSWORD RESET HANDLERS =====

  const handleMarkRead = async (id: string) => {
    if (!token) return;
    try {
      await markPasswordResetRead(token, id);
      showMessage("تم وضع علامة مقروء");
      fetchPasswordResets();
      fetchCounts();
    } catch (e: any) {
      showMessage(e.message || "خطأ", "error");
    }
  };

  const handleMarkAllRead = async () => {
    if (!token) return;
    try {
      await markAllPasswordResetsRead(token);
      showMessage("تم وضع علامة مقروء للكل");
      fetchPasswordResets();
      fetchCounts();
    } catch (e: any) {
      showMessage(e.message || "خطأ", "error");
    }
  };

  const extractCode = (message: string) => {
    const match = message.match(/الرمز:\s*(\d{6})/);
    return match ? match[1] : "";
  };

  const extractUser = (message: string) => {
    const nameMatch = message.match(/الاسم:\s*([^\n]+)/);
    const phoneMatch = message.match(/الهاتف:\s*([^\n]+)/);
    return { name: nameMatch?.[1]?.trim() || "", phone: phoneMatch?.[1]?.trim() || "" };
  };

  // ===== ALERT HANDLERS =====

  const handleCreateAlert = async () => {
    if (!token || !newAlert.title.trim() || !newAlert.message.trim()) return;
    try {
      await createSystemAlert(token, newAlert);
      showMessage("تم إنشاء التنبيه");
      setShowCreateAlert(false);
      setNewAlert({ title: "", message: "", severity: "Medium", category: "Manual", priority: "Medium" });
      fetchAlerts();
    } catch (e: any) {
      showMessage(e.message || "خطأ", "error");
    }
  };

  const handleUpdateAlertStatus = async (id: string, status: string) => {
    if (!token) return;
    try {
      await updateSystemAlertStatus(token, id, status);
      showMessage("تم التحديث");
      fetchAlerts();
    } catch (e: any) {
      showMessage(e.message || "خطأ", "error");
    }
  };

  const handleDeleteAlert = async (id: string) => {
    if (!token) return;
    try {
      await deleteSystemAlert(token, id);
      showMessage("تم الحذف");
      setSelectedAlert(null);
      fetchAlerts();
      fetchCounts();
    } catch (e: any) {
      showMessage(e.message || "خطأ", "error");
    }
  };

  // ===== RENDER HELPERS =====

  const renderMessage = () => {
    if (!message) return null;
    return (
      <div className={`fixed top-4 left-1/2 -translate-x-1/2 z-50 px-4 py-2 rounded-lg shadow-lg text-sm font-medium ${messageType === "success" ? "bg-green-600 text-white" : "bg-red-600 text-white"}`}>
        {message}
      </div>
    );
  };

  // ===== TICKETS TAB =====
  const renderTickets = () => (
    <div className="space-y-4">
      <OperationFilters
        statusFilter={ticketStatusFilter}
        onStatusChange={setTicketStatusFilter}
        priorityFilter={ticketPriorityFilter}
        onPriorityChange={setTicketPriorityFilter}
        showPriority
      />
      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>المعرف</TableHead>
              <TableHead>الرقم</TableHead>
              <TableHead>النوع</TableHead>
              <TableHead>العنوان</TableHead>
              <TableHead>المرسل</TableHead>
              <TableHead>الأولوية</TableHead>
              <TableHead>الحالة</TableHead>
              <TableHead>التاريخ</TableHead>
              <TableHead>إجراء</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {ticketLoading ? (
              <TableRow><TableCell colSpan={9} className="text-center py-8 text-muted-foreground">جاري التحميل...</TableCell></TableRow>
            ) : tickets.length === 0 ? (
              <TableRow><TableCell colSpan={9} className="text-center py-8 text-muted-foreground">لا توجد تذاكر</TableCell></TableRow>
            ) : tickets.map((ticket) => (
              <TableRow key={ticket.id} className="cursor-pointer hover:bg-muted/50" onClick={() => handleViewTicket(ticket)}>
                <TableCell className="font-mono text-xs">{ticket.ticketNumber}</TableCell>
                <TableCell className="font-mono text-xs">{ticket.id.slice(0, 8)}</TableCell>
                <TableCell><Badge variant="outline">{ticket.ticketType}</Badge></TableCell>
                <TableCell className="max-w-[200px] truncate">{ticket.subject}</TableCell>
                <TableCell>
                  <UserBadge role={ticket.userRole ?? (ticket.barberName ? "Barber" : "Customer")} />
                  <span className="text-xs text-muted-foreground block mt-0.5">{ticket.userName}</span>
                </TableCell>
                <TableCell><PriorityBadge priority={ticket.priority} /></TableCell>
                <TableCell><StatusBadge status={ticket.status} /></TableCell>
                <TableCell className="text-xs whitespace-nowrap">{new Date(ticket.createdAt).toLocaleDateString("ar-EG")}</TableCell>
                <TableCell>
                  <Button variant="ghost" size="icon" onClick={(e) => { e.stopPropagation(); handleViewTicket(ticket); }}>
                    <Eye className="size-4" />
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      {selectedTicket && ticketDetail && (
        <OperationDetailCard
          item={{
            id: ticketDetail.id,
            title: `${ticketDetail.ticketNumber} - ${ticketDetail.subject}`,
            subtitle: ticketDetail.userName,
            status: ticketDetail.status,
            priority: ticketDetail.priority,
            role: ticketDetail.userRole ?? (ticketDetail.barberName ? "Barber" : "Customer"),
            createdAt: ticketDetail.createdAt,
            relatedEntityType: "SupportTicket",
            relatedEntityId: ticketDetail.id,
            message: ticketDetail.description,
          }}
          onClose={() => { setSelectedTicket(null); setTicketDetail(null); }}
          actions={
            <div className="space-y-3 w-full">
              {ticketDetail.status !== "Closed" && ticketDetail.status !== "Resolved" && (
                <>
                  <div className="flex gap-2">
                    <Button size="sm" onClick={() => handleUpdateStatus(ticketDetail.id, "Closed")}>تم الحل</Button>
                    <Button size="sm" variant="outline" onClick={() => handleUpdateStatus(ticketDetail.id, "Waiting Customer")}>بانتظار الزبون</Button>
                  </div>
                  <div className="flex gap-2">
                    <Input placeholder="رد..." value={replyText} onChange={(e) => setReplyText(e.target.value)} className="flex-1" />
                    <Button size="sm" onClick={() => handleReply(ticketDetail.id)} disabled={!replyText.trim()}>
                      <Send className="size-4" />
                    </Button>
                  </div>
                </>
              )}
              {ticketDetail.replies && ticketDetail.replies.length > 0 && (
                <div className="space-y-2 mt-3">
                  <span className="text-xs text-muted-foreground font-medium">الردود:</span>
                  {ticketDetail.replies.map((r: any) => (
                    <div key={r.id} className={`p-2 rounded text-sm ${r.senderRole === "Admin" ? "bg-primary/10 border border-primary/20" : "bg-muted"}`}>
                      <div className="flex items-center gap-2 mb-1">
                        <UserBadge role={r.senderRole} />
                        <span className="text-xs text-muted-foreground">{new Date(r.createdAt).toLocaleString("ar-EG")}</span>
                      </div>
                      <p>{r.message}</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          }
        />
      )}
    </div>
  );

  // ===== VERIFICATIONS TAB =====
  const renderVerifications = () => (
    <div className="space-y-4">
      <OperationFilters
        statusFilter={verifyStatusFilter}
        onStatusChange={setVerifyStatusFilter}
        statusOptions={[
          { value: "all", label: "الكل" },
          { value: "Pending", label: "قيد الانتظار" },
          { value: "Verified", label: "تم التحقق" },
          { value: "Rejected", label: "مرفوض" },
        ]}
      />
      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>الاسم</TableHead>
              <TableHead>الهاتف</TableHead>
              <TableHead>الحالة</TableHead>
              <TableHead>التاريخ</TableHead>
              <TableHead>إجراء</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {verifyLoading ? (
              <TableRow><TableCell colSpan={5} className="text-center py-8 text-muted-foreground">جاري التحميل...</TableCell></TableRow>
            ) : verifications.length === 0 ? (
              <TableRow><TableCell colSpan={5} className="text-center py-8 text-muted-foreground">لا يوجد طلبات</TableCell></TableRow>
            ) : verifications.map((c) => (
              <TableRow key={c.id} className={c.phoneVerificationStatus === "Pending" ? "bg-yellow-50" : ""}>
                <TableCell className="font-medium">{c.fullName}</TableCell>
                <TableCell className="font-mono">{c.phoneNumber}</TableCell>
                <TableCell><StatusBadge status={c.phoneVerificationStatus} /></TableCell>
                <TableCell className="text-xs">{new Date(c.createdAt).toLocaleDateString("ar-EG")}</TableCell>
                <TableCell>
                  {c.phoneVerificationStatus === "Pending" ? (
                    <div className="flex gap-1">
                      <Button variant="ghost" size="icon" title="إرسال OTP" onClick={() => handleVerifyPhone(c.id)}>
                        <Send className="size-4 text-green-600" />
                      </Button>
                      <Button variant="ghost" size="icon" title="رفض" onClick={() => handleRejectVerification(c.id)}>
                        <Trash2 className="size-4 text-red-600" />
                      </Button>
                    </div>
                  ) : (
                    <span className="text-xs text-muted-foreground">-</span>
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  );

  // ===== PASSWORD RESETS TAB =====
  const renderPasswordResets = () => (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <OperationFilters
          statusFilter={prStatusFilter}
          onStatusChange={setPrStatusFilter}
          statusOptions={[
            { value: "all", label: "الكل" },
            { value: "unread", label: "غير مقروء" },
            { value: "read", label: "مقروء" },
          ]}
        />
        <Button variant="outline" size="sm" onClick={handleMarkAllRead}>
          <CheckCircle className="size-4 ml-1" /> وضع علامة مقروء للكل
        </Button>
      </div>
      <div className="space-y-3">
        {passwordResets.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">لا توجد طلبات</div>
        ) : passwordResets.map((req) => {
          const user = extractUser(req.message);
          const code = extractCode(req.message);
          return (
            <Card key={req.id} className={req.isRead ? "opacity-60" : "border-amber-500"}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between">
                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <KeyRound className="size-4 text-purple-600" />
                      <span className="font-medium text-sm">{user.name || "مستخدم"}</span>
                      <Badge variant={req.isRead ? "secondary" : "default"}>{req.isRead ? "مقروء" : "جديد"}</Badge>
                    </div>
                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <span className="flex items-center gap-1"><Phone className="size-3" /> {user.phone}</span>
                      <span className="flex items-center gap-1"><Clock className="size-3" /> {new Date(req.createdAt).toLocaleString("ar-EG")}</span>
                    </div>
                    {code && (
                      <div className="flex items-center gap-2 mt-2">
                        <span className="text-xs text-muted-foreground">الكود:</span>
                        <span className="font-mono text-lg font-bold text-primary bg-primary/10 px-3 py-1 rounded">{code}</span>
                        <Button
                          variant="ghost" size="icon"
                          onClick={() => {
                            navigator.clipboard.writeText(code);
                            setCopiedId(req.id);
                            setTimeout(() => setCopiedId(null), 2000);
                          }}
                        >
                          {copiedId === req.id ? <CheckCircle className="size-4 text-green-600" /> : <Copy className="size-4" />}
                        </Button>
                      </div>
                    )}
                  </div>
                  <div className="flex gap-1">
                    {!req.isRead && (
                      <Button variant="ghost" size="icon" onClick={() => handleMarkRead(req.id)}>
                        <CheckCircle className="size-4 text-blue-600" />
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );

  // ===== ALERTS TAB =====
  const renderAlerts = () => (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <OperationFilters
          statusFilter={alertStatusFilter}
          onStatusChange={setAlertStatusFilter}
          priorityFilter={alertSeverityFilter}
          onPriorityChange={setAlertSeverityFilter}
          statusOptions={[
            { value: "all", label: "الكل" },
            { value: "New", label: "جديد" },
            { value: "Acknowledged", label: "تم الاعتراف" },
            { value: "Viewed", label: "تمت المشاهدة" },
            { value: "Resolved", label: "تم الحل" },
          ]}
          showPriority
        />
        <Button onClick={() => setShowCreateAlert(true)}>
          <Plus className="size-4 ml-1" /> إنشاء تنبيه
        </Button>
      </div>

      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>العنوان</TableHead>
              <TableHead>المستوى</TableHead>
              <TableHead>الفئة</TableHead>
              <TableHead>الأولوية</TableHead>
              <TableHead>الحالة</TableHead>
              <TableHead>التاريخ</TableHead>
              <TableHead>إجراء</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {alertLoading ? (
              <TableRow><TableCell colSpan={7} className="text-center py-8 text-muted-foreground">جاري التحميل...</TableCell></TableRow>
            ) : alerts.length === 0 ? (
              <TableRow><TableCell colSpan={7} className="text-center py-8 text-muted-foreground">لا توجد تنبيهات</TableCell></TableRow>
            ) : alerts.map((alert) => (
              <TableRow key={alert.id} className={!alert.readAt ? "bg-blue-50" : ""} onClick={() => setSelectedAlert(alert)}>
                <TableCell className="font-medium max-w-[200px] truncate">{alert.title}</TableCell>
                <TableCell><Badge variant="outline">{alert.severity}</Badge></TableCell>
                <TableCell className="text-sm">{alert.category}</TableCell>
                <TableCell><PriorityBadge priority={alert.priority} /></TableCell>
                <TableCell><StatusBadge status={alert.status} /></TableCell>
                <TableCell className="text-xs whitespace-nowrap">{new Date(alert.createdAt).toLocaleDateString("ar-EG")}</TableCell>
                <TableCell>
                  <div className="flex gap-1">
                    <Button variant="ghost" size="icon" onClick={(e) => { e.stopPropagation(); setSelectedAlert(alert); }}>
                      <Eye className="size-4" />
                    </Button>
                    <Button variant="ghost" size="icon" onClick={(e) => { e.stopPropagation(); handleDeleteAlert(alert.id); }}>
                      <Trash2 className="size-4 text-red-600" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      {selectedAlert && (
        <OperationDetailCard
          item={{
            id: selectedAlert.id,
            title: selectedAlert.title,
            subtitle: selectedAlert.source,
            status: selectedAlert.status,
            priority: selectedAlert.priority,
            createdAt: selectedAlert.createdAt,
            relatedEntityType: selectedAlert.relatedEntityType || undefined,
            relatedEntityId: selectedAlert.relatedEntityId || undefined,
            message: selectedAlert.message,
          }}
          onClose={() => setSelectedAlert(null)}
          actions={
            <div className="flex gap-2">
              {selectedAlert.status === "New" && (
                <Button size="sm" onClick={() => handleUpdateAlertStatus(selectedAlert.id, "Acknowledged")}>تم الاعتراف</Button>
              )}
              {selectedAlert.status !== "Resolved" && (
                <Button size="sm" variant="outline" onClick={() => handleUpdateAlertStatus(selectedAlert.id, "Resolved")}>تم الحل</Button>
              )}
            </div>
          }
        />
      )}

      {showCreateAlert && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">إنشاء تنبيه جديد</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Input placeholder="العنوان" value={newAlert.title} onChange={(e) => setNewAlert({ ...newAlert, title: e.target.value })} />
            <Input placeholder="المحتوى" value={newAlert.message} onChange={(e) => setNewAlert({ ...newAlert, message: e.target.value })} />
            <div className="flex gap-2">
              <Select value={newAlert.severity} onValueChange={(v) => setNewAlert({ ...newAlert, severity: v ?? "Medium" })}>
                <SelectTrigger className="w-[140px]">
                  <SelectValue placeholder="المستوى">
                    {(v: string | null) => (!v ? "المستوى" : { Info: "معلومات", Warning: "تحذير", Error: "خطأ", Critical: "حرج" }[v] ?? "المستوى")}
                  </SelectValue>
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Info">معلومات</SelectItem>
                  <SelectItem value="Warning">تحذير</SelectItem>
                  <SelectItem value="Error">خطأ</SelectItem>
                  <SelectItem value="Critical">حرج</SelectItem>
                </SelectContent>
              </Select>
              <Select value={newAlert.priority} onValueChange={(v) => setNewAlert({ ...newAlert, priority: v ?? "Medium" })}>
                <SelectTrigger className="w-[140px]">
                  <SelectValue placeholder="الأولوية">
                    {(v: string | null) => (!v ? "الأولوية" : { Low: "منخفضة", Medium: "متوسطة", High: "عالية", Critical: "عاجلة" }[v] ?? "الأولوية")}
                  </SelectValue>
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Low">منخفضة</SelectItem>
                  <SelectItem value="Medium">متوسطة</SelectItem>
                  <SelectItem value="High">عالية</SelectItem>
                  <SelectItem value="Critical">عاجلة</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex gap-2">
              <Button onClick={handleCreateAlert} disabled={!newAlert.title.trim() || !newAlert.message.trim()}>إرسال</Button>
              <Button variant="outline" onClick={() => setShowCreateAlert(false)}>إلغاء</Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );

  // ===== MAIN TAB CONTENT =====
  const tabContent = useMemo(() => {
    switch (activeTab) {
      case "tickets": return renderTickets();
      case "verifications": return renderVerifications();
      case "passwordResets": return renderPasswordResets();
      case "alerts": return renderAlerts();
      case "auditLog": return <AuditLogTable />;
      default: return null;
    }
  }, [activeTab, tickets, ticketDetail, replyText, verifications, passwordResets, alerts, selectedTicket, selectedAlert, selectedVerify, selectedPr, alertStatusFilter, alertSeverityFilter, ticketStatusFilter, ticketPriorityFilter, verifyStatusFilter, prStatusFilter, showCreateAlert, newAlert, copiedId, ticketLoading, verifyLoading, alertLoading]);

  return (
    <div className="space-y-6">
      {renderMessage()}

      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">مركز العمليات</h1>
          <p className="text-sm text-muted-foreground">إدارة التذاكر والتحقق من الهوية وإعادة كلمة المرور والتنبيهات</p>
        </div>
        <Button variant="outline" onClick={() => { fetchCounts(); if (activeTab === "tickets") fetchTickets(); else if (activeTab === "verifications") fetchVerifications(); else if (activeTab === "passwordResets") fetchPasswordResets(); else if (activeTab === "alerts") fetchAlerts(); }}>
          <RefreshCw className="size-4 ml-1" /> تحديث
        </Button>
      </div>

      <OperationStatsCards data={counts} activeTab={activeTab} onTabChange={setActiveTab} />

      <div className="flex gap-1 border-b overflow-x-auto">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex items-center gap-2 px-4 py-2.5 text-sm font-medium whitespace-nowrap border-b-2 transition-colors ${
              activeTab === tab.key
                ? "border-primary text-primary"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            <tab.icon className="size-4" />
            {tab.label}
          </button>
        ))}
      </div>

      {tabContent}
    </div>
  );
}
