const API_BASE = process.env.NEXT_PUBLIC_API_URL || "";

export interface LoginResponse {
  token: string;
  refreshToken: string;
  expiration: string;
  role: string;
  fullName: string;
  userId: string;
}

export interface DashboardStats {
  totalBarbers: number;
  totalCustomers: number;
  totalBookings: number;
  activeBookings: number;
  completedBookings: number;
  cancelledBookings: number;
  totalRevenue: number;
  todayBookings: number;
  activeSubscriptions: number;
  monthlyRevenue: number;
  topBarbers: Array<{
    barberName: string;
    shopName: string;
    bookingCount: number;
    revenue: number;
  }>;
  recentBookings: Array<{
    id: string;
    customerName: string;
    barberName: string;
    shopName: string;
    serviceName: string;
    bookingDate: string;
    totalPrice: number;
    finalPrice: number;
    status: string;
    paymentStatus: string;
  }>;
  cityStats: Array<{ city: string; count: number }>;
}

export interface Barber {
  id: string;
  shopName: string;
  ownerName: string;
  phoneNumber: string;
  city: string;
  address: string;
  subscriptionPlan: string;
  averageRating: number;
  reviewCount: number;
  isUserActive: boolean;
  createdAt: string;
}

export interface Customer {
  id: string;
  fullName: string;
  phoneNumber: string;
  email: string;
  city: string;
  isActive: boolean;
  totalBookings: number;
  noShowCount: number;
  isBookingBlocked: boolean;
  blockReason: string | null;
  dailyCancelCount: number;
  createdAt: string;
}

async function apiFetch<T>(path: string, token: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...options?.headers,
    },
  });

  if (!res.ok) {
    if (res.status === 401) {
      localStorage.removeItem("admin_auth");
      window.location.href = "/login";
      throw new Error("Session expired. Please login again.");
    }
    let msg = res.statusText;
    try {
      const body = await res.json();
      msg = body.message || JSON.stringify(body);
    } catch {}
    throw new Error(msg || "API Error");
  }

  return res.json();
}

export async function login(phoneNumber: string, password: string): Promise<LoginResponse> {
  const res = await fetch(`${API_BASE}/api/admin/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ phoneNumber, password }),
  });

  if (!res.ok) {
    const error = await res.json().catch(() => ({ message: "Login failed" }));
    throw new Error(error.message || "Login failed");
  }

  return res.json();
}

export async function getDashboard(token: string): Promise<DashboardStats> {
  return apiFetch<DashboardStats>("/api/admin/dashboard", token);
}

export async function getBarbers(token: string, page = 1): Promise<{ barbers: Barber[]; totalCount: number }> {
  return apiFetch(`/api/admin/barbers?page=${page}&pageSize=20`, token);
}

export async function getCustomers(token: string, page = 1): Promise<{ customers: Customer[]; totalCount: number }> {
  return apiFetch(`/api/admin/customers?page=${page}&pageSize=20`, token);
}

export async function toggleBarberActive(token: string, id: string) {
  return apiFetch(`/api/admin/barbers/${id}/toggle-active`, token, { method: "PUT" });
}

export interface Booking {
  id: string;
  customerName: string;
  customerPhone: string;
  barberName: string;
  shopName: string;
  serviceName: string;
  bookingDate: string;
  totalPrice: number;
  finalPrice: number;
  status: string;
  paymentStatus: string;
  paymentMethod: string;
  createdAt: string;
}

export async function getBookings(token: string, page = 1, status?: string): Promise<{ bookings: Booking[]; totalCount: number }> {
  const params = new URLSearchParams({ page: String(page), pageSize: "20" });
  if (status) params.set("status", status);
  return apiFetch(`/api/admin/bookings?${params}`, token);
}

// ===== SUBSCRIPTION MANAGEMENT =====

export interface SubscriptionPlan {
  id: string;
  name: string;
  nameArabic: string;
  description: string;
  monthlyPrice: number;
  yearlyPrice: number;
  maxServices: number;
  maxPhotos: number;
  maxBookingsPerMonth: number;
  maxEmployees: number;
  analyticsLevel: string;
  hasPromoCodes: boolean;
  hasPrioritySupport: boolean;
  isActive: boolean;
}

export interface Subscription {
  subscriptionId: string;
  planId: string;
  planName: string;
  planNameArabic: string;
  amountPaid: number;
  paymentMethod: string;
  status: string;
  isYearly: boolean;
  startDate: string;
  endDate: string;
  daysRemaining: number;
  maxServices: number;
  maxPhotos: number;
  maxBookingsPerMonth: number;
  maxEmployees: number;
  analyticsLevel: string;
  hasPromoCodes: boolean;
  hasPrioritySupport: boolean;
  currentBookingsCount: number;
  shopName: string;
  ownerName: string;
}

export interface SubscriptionStats {
  totalActiveSubscriptions: number;
  totalBasicSubscriptions: number;
  totalProSubscriptions: number;
  totalPremiumSubscriptions: number;
  totalMonthlyRevenue: number;
  totalYearlyRevenue: number;
  expiredThisMonth: number;
  newThisMonth: number;
}

export async function getSubscriptions(token: string, status?: string, page = 1): Promise<Subscription[]> {
  const params = new URLSearchParams({ page: String(page), pageSize: "20" });
  if (status) params.set("status", status);
  return apiFetch(`/api/admin/subscriptions?${params}`, token);
}

export async function getSubscriptionStats(token: string): Promise<SubscriptionStats> {
  return apiFetch("/api/admin/subscriptions/stats", token);
}

export async function getSubscriptionPlans(token: string): Promise<SubscriptionPlan[]> {
  return apiFetch("/api/admin/subscription-plans", token);
}

export async function extendSubscription(token: string, id: string, days: number) {
  return apiFetch(`/api/admin/subscriptions/${id}/extend`, token, {
    method: "POST",
    body: JSON.stringify({ days }),
  });
}

export async function forceChangePlan(token: string, barberId: string, planId: string) {
  return apiFetch(`/api/admin/barbers/${barberId}/change-plan`, token, {
    method: "POST",
    body: JSON.stringify({ planId }),
  });
}

export async function updateSubscriptionPlan(token: string, id: string, data: Partial<SubscriptionPlan>) {
  return apiFetch(`/api/admin/subscription-plans/${id}`, token, {
    method: "PUT",
    body: JSON.stringify(data),
  });
}

// ===== PAYMENT REQUESTS =====

export interface PaymentRequest {
  id: string;
  paymentMethod: string;
  amount: number;
  planName: string;
  isYearly: boolean;
  receiptImageUrl?: string;
  status: string;
  adminNotes?: string;
  createdAt: string;
  reviewedAt?: string;
  isUpgrade: boolean;
  fromPlanName?: string;
  barberName: string;
  shopName: string;
  phoneNumber: string;
}

export async function getPaymentRequests(token: string, status?: string): Promise<PaymentRequest[]> {
  const params = new URLSearchParams();
  if (status) params.set("status", status);
  const qs = params.toString();
  return apiFetch(`/api/admin/payments${qs ? `?${qs}` : ""}`, token);
}

export async function getPendingPaymentCount(token: string): Promise<number> {
  const res = await apiFetch<{ count: number }>("/api/admin/payments/pending-count", token);
  return res.count;
}

export async function reviewPaymentRequest(token: string, id: string, status: "approved" | "rejected", adminNotes?: string) {
  return apiFetch(`/api/admin/payments/${id}/review`, token, {
    method: "POST",
    body: JSON.stringify({ status, adminNotes }),
  });
}

// ===== SUPPORT TICKETS =====

export interface SupportTicket {
  id: string;
  ticketNumber: string;
  ticketType: string;
  subject: string;
  description: string;
  status: string;
  priority: string;
  attachmentUrl?: string;
  userName?: string;
  userPhone?: string;
  userRole: string;
  subscriptionPlan?: string;
  barberName?: string;
  shopName?: string;
  assignedTo?: string;
  rating?: number;
  ratingComment?: string;
  createdAt: string;
  lastReplyAt?: string;
  closedAt?: string;
  replies: TicketReply[];
}

export interface TicketReply {
  id: string;
  senderRole: string;
  senderName: string;
  message: string;
  attachmentUrl?: string;
  createdAt: string;
}

export async function getSupportTickets(token: string, status?: string, priority?: string, ticketType?: string): Promise<SupportTicket[]> {
  const params = new URLSearchParams();
  if (status) params.set("status", status);
  if (priority) params.set("priority", priority);
  if (ticketType) params.set("ticketType", ticketType);
  const qs = params.toString();
  return apiFetch(`/api/admin/support/tickets${qs ? `?${qs}` : ""}`, token);
}

export async function getSupportTicketDetail(token: string, id: string): Promise<SupportTicket> {
  return apiFetch(`/api/admin/support/tickets/${id}`, token);
}

export async function replyToTicket(token: string, id: string, message: string): Promise<TicketReply> {
  return apiFetch(`/api/admin/support/tickets/${id}/reply`, token, {
    method: "POST",
    body: JSON.stringify({ message }),
  });
}

export async function updateTicketStatus(token: string, id: string, status: string): Promise<void> {
  await apiFetch(`/api/admin/support/tickets/${id}/status`, token, {
    method: "PUT",
    body: JSON.stringify({ status }),
  });
}

// ===== CUSTOMER PHONE VERIFICATION =====

export interface CustomerVerification {
  id: string;
  fullName: string;
  phoneNumber: string;
  email: string;
  city: string;
  profileImageUrl: string;
  phoneVerificationStatus: string;
  isActive: boolean;
  createdAt: string;
}

export async function getCustomerVerifications(token: string, status?: string, page = 1): Promise<{ customers: CustomerVerification[]; totalCount: number }> {
  const params = new URLSearchParams({ page: String(page), pageSize: "20" });
  if (status) params.set("status", status);
  return apiFetch(`/api/admin/customer-verifications?${params}`, token);
}

export async function getCustomerVerificationDetail(token: string, id: string): Promise<CustomerVerification> {
  return apiFetch(`/api/admin/customer-verifications/${id}`, token);
}

export async function sendCustomerVerificationOtp(token: string, id: string): Promise<{ message: string; code: string }> {
  return apiFetch(`/api/admin/customer-verifications/${id}/send-otp`, token, {
    method: "POST",
  });
}

export async function verifyCustomerPhone(token: string, id: string, code: string): Promise<{ message: string }> {
  return apiFetch(`/api/admin/customer-verifications/${id}/verify`, token, {
    method: "POST",
    body: JSON.stringify({ code }),
  });
}

export async function rejectCustomerVerification(token: string, id: string, reason?: string): Promise<{ message: string }> {
  return apiFetch(`/api/admin/customer-verifications/${id}/reject`, token, {
    method: "POST",
    body: JSON.stringify({ reason }),
  });
}

export async function getPendingCustomerVerificationCount(token: string): Promise<number> {
  const res = await apiFetch<{ count: number }>("/api/admin/customer-verifications/pending-count", token);
  return res.count;
}

// ===== PASSWORD RESETS =====

export interface PasswordResetUser {
  id: string;
  fullName: string;
  phoneNumber: string;
  role: string;
  isActive: boolean;
  createdAt: string;
}

export async function getPasswordResetUsers(token: string, role?: string, search?: string, page = 1): Promise<{ users: PasswordResetUser[]; totalCount: number }> {
  const params = new URLSearchParams({ page: String(page), pageSize: "20" });
  if (role) params.set("role", role);
  if (search) params.set("search", search);
  return apiFetch(`/api/admin/password-resets?${params}`, token);
}

export async function sendPasswordResetOtp(token: string, id: string): Promise<{ message: string; code: string }> {
  return apiFetch(`/api/admin/password-resets/${id}/send-otp`, token, {
    method: "POST",
  });
}

export async function getPasswordResetNotificationCount(token: string): Promise<number> {
  const res = await apiFetch<{ count: number }>("/api/admin/password-reset-notifications", token);
  return res.count;
}

export interface PasswordResetRequest {
  id: string;
  title: string;
  message: string;
  isRead: boolean;
  createdAt: string;
}

export async function getPasswordResetRequests(token: string): Promise<{ notifications: PasswordResetRequest[] }> {
  return apiFetch("/api/admin/password-reset-requests", token);
}

export async function markPasswordResetRequestRead(token: string, id: string): Promise<void> {
  await apiFetch(`/api/admin/password-reset-requests/${id}/mark-read`, token, {
    method: "POST",
  });
}

export async function markPasswordResetNotificationsRead(token: string): Promise<void> {
  await apiFetch("/api/admin/password-reset-notifications/mark-read", token, {
    method: "POST",
  });
}

export async function unblockCustomer(token: string, id: string): Promise<void> {
  await apiFetch(`/api/admin/customers/${id}/unblock`, token, {
    method: "PUT",
  });
}

// ===== OPERATIONS CENTER =====

export interface OperationsCounts {
  pendingActions: {
    tickets: number;
    passwordResets: number;
    verifications: number;
    complaints: number;
    total: number;
  };
  alerts: {
    new: number;
    critical: number;
    total: number;
  };
  subscriptions: {
    new: number;
    cancelPending: number;
    total: number;
  };
  payments: {
    pending: number;
  };
  unreadNotifications: number;
}

export interface SystemAlert {
  id: string;
  title: string;
  message: string;
  severity: string;
  category: string;
  status: string;
  priority: string;
  source: string;
  isAutoGenerated: boolean;
  readAt: string | null;
  createdBy: string | null;
  relatedEntityType: string | null;
  relatedEntityId: string | null;
  targetUserId: string | null;
  targetUserType: string | null;
  targetUserName: string | null;
  createdAt: string;
}

export interface AuditLogEntry {
  id: string;
  action: string;
  entityType: string;
  entityId: string | null;
  adminId: string;
  adminName: string;
  details: string | null;
  oldValue: string | null;
  newValue: string | null;
  createdAt: string;
}

export interface RecentActivity {
  type: string;
  title: string;
  subtitle: string;
  status: string;
  icon: string;
  color: string;
  createdAt: string;
}

export interface TimelineEvent {
  time: string;
  action: string;
  icon: string;
  color: string;
  by: string;
}

export async function getOperationsCounts(token: string): Promise<OperationsCounts> {
  return apiFetch("/api/admin/operations/counts", token);
}

export async function getRecentActivity(token: string): Promise<RecentActivity[]> {
  return apiFetch("/api/admin/operations/recent", token);
}

export async function getSystemAlerts(token: string, filters?: { status?: string; severity?: string; category?: string; priority?: string; search?: string }): Promise<SystemAlert[]> {
  const params = new URLSearchParams();
  if (filters?.status) params.set("status", filters.status);
  if (filters?.severity) params.set("severity", filters.severity);
  if (filters?.category) params.set("category", filters.category);
  if (filters?.priority) params.set("priority", filters.priority);
  if (filters?.search) params.set("search", filters.search);
  const qs = params.toString();
  return apiFetch(`/api/admin/operations/alerts${qs ? `?${qs}` : ""}`, token);
}

export async function createSystemAlert(token: string, data: { title: string; message: string; severity?: string; category?: string; priority?: string; targetUserId?: string; targetUserType?: string }): Promise<void> {
  await apiFetch("/api/admin/operations/alerts", token, {
    method: "POST",
    body: JSON.stringify(data),
  });
}

export async function updateSystemAlertStatus(token: string, id: string, status: string): Promise<void> {
  await apiFetch(`/api/admin/operations/alerts/${id}/status`, token, {
    method: "PUT",
    body: JSON.stringify({ status }),
  });
}

export async function deleteSystemAlert(token: string, id: string): Promise<void> {
  await apiFetch(`/api/admin/operations/alerts/${id}`, token, { method: "DELETE" });
}

export async function getAuditLog(token: string, filters?: { action?: string; entityType?: string; page?: number }): Promise<{ logs: AuditLogEntry[]; totalCount: number }> {
  const params = new URLSearchParams();
  if (filters?.action) params.set("action", filters.action);
  if (filters?.entityType) params.set("entityType", filters.entityType);
  if (filters?.page) params.set("page", String(filters.page));
  const qs = params.toString();
  return apiFetch(`/api/admin/operations/audit-log${qs ? `?${qs}` : ""}`, token);
}

export async function getActivityTimeline(token: string, entityType: string, entityId: string): Promise<TimelineEvent[]> {
  return apiFetch(`/api/admin/operations/timeline/${entityType}/${entityId}`, token);
}

export async function getOperationsTickets(token: string, filters?: { status?: string; priority?: string; ticketType?: string; role?: string }): Promise<any[]> {
  const params = new URLSearchParams();
  if (filters?.status) params.set("status", filters.status);
  if (filters?.priority) params.set("priority", filters.priority);
  if (filters?.ticketType) params.set("ticketType", filters.ticketType);
  if (filters?.role) params.set("role", filters.role);
  const qs = params.toString();
  return apiFetch(`/api/admin/operations/tickets${qs ? `?${qs}` : ""}`, token);
}

export async function getOperationsVerifications(token: string, status?: string, page = 1): Promise<{ customers: any[]; totalCount: number }> {
  const params = new URLSearchParams({ page: String(page), pageSize: "20" });
  if (status) params.set("status", status);
  return apiFetch(`/api/admin/operations/verifications?${params}`, token);
}

export async function verifyCustomerPhoneOps(token: string, id: string): Promise<{ message: string; code: string }> {
  return apiFetch(`/api/admin/operations/verifications/${id}/send-otp`, token, { method: "POST" });
}

export async function rejectCustomerVerificationOps(token: string, id: string, reason?: string): Promise<{ message: string }> {
  return apiFetch(`/api/admin/operations/verifications/${id}/reject`, token, {
    method: "POST",
    body: JSON.stringify({ reason }),
  });
}

export async function getOperationsPasswordResets(token: string, status?: string, page = 1): Promise<{ notifications: any[]; totalCount: number }> {
  const params = new URLSearchParams({ page: String(page), pageSize: "20" });
  if (status) params.set("status", status);
  return apiFetch(`/api/admin/operations/password-resets?${params}`, token);
}

export async function markPasswordResetRead(token: string, id: string): Promise<void> {
  await apiFetch(`/api/admin/operations/password-resets/${id}/mark-read`, token, { method: "POST" });
}

export async function markAllPasswordResetsRead(token: string): Promise<void> {
  await apiFetch("/api/admin/operations/password-resets/mark-all-read", token, { method: "POST" });
}
