"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  getPaymentRequests,
  reviewPaymentRequest,
  PaymentRequest,
} from "@/lib/api";
import { Banknote, Check, X, Eye } from "lucide-react";

export default function PaymentsPage() {
  const { token } = useAuth();
  const [payments, setPayments] = useState<PaymentRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("");
  const [rejectingId, setRejectingId] = useState<string | null>(null);
  const [rejectNotes, setRejectNotes] = useState("");
  const [receiptModal, setReceiptModal] = useState<string | null>(null);

  const load = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const data = await getPaymentRequests(token, filter || undefined);
      setPayments(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [filter, token]);

  const handleReview = async (id: string, status: "approved" | "rejected") => {
    if (!token) return;
    try {
      await reviewPaymentRequest(token, id, status, status === "rejected" ? rejectNotes : undefined);
      setRejectingId(null);
      setRejectNotes("");
      load();
    } catch (e) {
      console.error(e);
    }
  };

  const planLabel = (name: string) => {
    if (name === "basic") return "الأساسية";
    if (name === "pro") return "الاحترافية";
    if (name === "premium") return "VIP";
    return name;
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <Banknote className="size-6" />
        <h1 className="text-2xl font-bold">طلبات الدفع</h1>
      </div>

      <div className="flex gap-2">
        {[
          { value: "", label: "الكل" },
          { value: "pending", label: "قيد المراجعة" },
          { value: "approved", label: "مقبول" },
          { value: "rejected", label: "مرفوض" },
        ].map((f) => (
          <Button
            key={f.value}
            variant={filter === f.value ? "default" : "outline"}
            size="sm"
            onClick={() => setFilter(f.value)}
          >
            {f.label}
          </Button>
        ))}
      </div>

      <Card>
        <CardContent className="p-0">
          {loading ? (
            <div className="p-8 text-center text-muted-foreground">جاري التحميل...</div>
          ) : payments.length === 0 ? (
            <div className="p-8 text-center text-muted-foreground">لا توجد طلبات</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>الحلاق</TableHead>
                  <TableHead>الخطة</TableHead>
                  <TableHead>المبلغ</TableHead>
                  <TableHead>طريقة الدفع</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead>التاريخ</TableHead>
                  <TableHead>الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {payments.map((p) => (
                  <TableRow key={p.id}>
                    <TableCell>
                      <div className="font-medium">{p.barberName}</div>
                      <div className="text-xs text-muted-foreground">{p.shopName}</div>
                      <div className="text-xs text-muted-foreground">{p.phoneNumber}</div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <span className="font-medium">{planLabel(p.planName)}</span>
                        {p.isUpgrade && p.fromPlanName && (
                          <Badge variant="outline" className="text-xs">
                            ترقية من {planLabel(p.fromPlanName)}
                          </Badge>
                        )}
                      </div>
                      <div className="text-xs text-muted-foreground">{p.isYearly ? "سنوي" : "شهري"}</div>
                    </TableCell>
                    <TableCell className="font-bold">{p.amount}₪</TableCell>
                    <TableCell>
                      <Badge variant={p.paymentMethod === "cash" ? "default" : "secondary"}>
                        {p.paymentMethod === "cash" ? "كاش" : "تحويل بنكي"}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <Badge variant={p.status === "approved" ? "default" : p.status === "rejected" ? "destructive" : "secondary"}>
                        {p.status === "pending" ? "قيد المراجعة" : p.status === "approved" ? "مقبول" : "مرفوض"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {new Date(p.createdAt).toLocaleDateString("ar-EG")}
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-1">
                        {p.receiptImageUrl && (
                          <Button variant="ghost" size="sm" onClick={() => setReceiptModal(p.receiptImageUrl!)}>
                            <Eye className="size-4" />
                          </Button>
                        )}
                        {p.status === "pending" && (
                          <>
                            <Button variant="ghost" size="sm" className="text-green-600" onClick={() => handleReview(p.id, "approved")}>
                              <Check className="size-4" />
                            </Button>
                            <Button variant="ghost" size="sm" className="text-red-600" onClick={() => setRejectingId(p.id)}>
                              <X className="size-4" />
                            </Button>
                          </>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {rejectingId && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setRejectingId(null)}>
          <Card className="w-full max-w-md" onClick={(e) => e.stopPropagation()}>
            <CardHeader>
              <CardTitle>رفض الطلب</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <textarea
                value={rejectNotes}
                onChange={(e) => setRejectNotes(e.target.value)}
                placeholder="سبب الرفض (اختياري)"
                className="w-full border rounded-lg p-3 text-sm"
                rows={3}
              />
              <div className="flex gap-3">
                <Button variant="destructive" className="flex-1" onClick={() => handleReview(rejectingId, "rejected")}>رفض</Button>
                <Button variant="outline" className="flex-1" onClick={() => { setRejectingId(null); setRejectNotes(""); }}>إلغاء</Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {receiptModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setReceiptModal(null)}>
          <Card className="w-full max-w-lg mx-4" onClick={(e) => e.stopPropagation()}>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle>إيصال التحويل</CardTitle>
              <Button variant="ghost" size="sm" onClick={() => setReceiptModal(null)}>✕</Button>
            </CardHeader>
            <CardContent>
              {receiptModal.startsWith("data:") ? (
                <img src={receiptModal} alt="Receipt" className="w-full rounded-lg" />
              ) : (
                <img src={`http://localhost:5170${receiptModal}`} alt="Receipt" className="w-full rounded-lg" />
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
