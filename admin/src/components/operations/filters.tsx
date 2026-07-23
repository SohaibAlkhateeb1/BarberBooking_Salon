"use client";

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Search } from "lucide-react";

interface FiltersProps {
  statusFilter: string;
  onStatusChange: (v: string) => void;
  priorityFilter?: string;
  onPriorityChange?: (v: string) => void;
  roleFilter?: string;
  onRoleChange?: (v: string) => void;
  search?: string;
  onSearchChange?: (v: string) => void;
  statusOptions?: { value: string; label: string }[];
  showRole?: boolean;
  showPriority?: boolean;
  showSearch?: boolean;
}

const defaultStatusOptions = [
  { value: "all", label: "الكل" },
  { value: "New", label: "جديد" },
  { value: "Open", label: "مفتوح" },
  { value: "In Progress", label: "قيد المراجعة" },
  { value: "Resolved", label: "تم الحل" },
  { value: "Closed", label: "مغلق" },
  { value: "Rejected", label: "مرفوض" },
];

const priorityOptions = [
  { value: "all", label: "الكل" },
  { value: "Low", label: "منخفضة" },
  { value: "Medium", label: "متوسطة" },
  { value: "High", label: "عالية" },
  { value: "Critical", label: "عاجلة" },
];

const roleOptions = [
  { value: "all", label: "الكل" },
  { value: "Customer", label: "زبون" },
  { value: "Barber", label: "حلاق" },
];

export function OperationFilters({
  statusFilter, onStatusChange,
  priorityFilter, onPriorityChange,
  roleFilter, onRoleChange,
  search, onSearchChange,
  statusOptions,
  showRole = false,
  showPriority = false,
  showSearch = false,
}: FiltersProps) {
  const opts = statusOptions || defaultStatusOptions;

  return (
    <div className="flex gap-2 flex-wrap items-center">
      <Select value={statusFilter} onValueChange={(v) => onStatusChange(v ?? "all")}>
        <SelectTrigger className="w-[140px]">
          <SelectValue placeholder="الحالة">
            {(v: string | null) => opts.find((o) => o.value === v)?.label ?? "الحالة"}
          </SelectValue>
        </SelectTrigger>
        <SelectContent>
          {opts.map((o) => (
            <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      {showPriority && onPriorityChange && (
        <Select value={priorityFilter || "all"} onValueChange={(v) => onPriorityChange(v ?? "all")}>
          <SelectTrigger className="w-[140px]">
            <SelectValue placeholder="الأولوية">
              {(v: string | null) => priorityOptions.find((o) => o.value === v)?.label ?? "الأولوية"}
            </SelectValue>
          </SelectTrigger>
          <SelectContent>
            {priorityOptions.map((o) => (
              <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      )}

      {showRole && onRoleChange && (
        <Select value={roleFilter || "all"} onValueChange={(v) => onRoleChange(v ?? "all")}>
          <SelectTrigger className="w-[140px]">
            <SelectValue placeholder="الدور">
              {(v: string | null) => roleOptions.find((o) => o.value === v)?.label ?? "الدور"}
            </SelectValue>
          </SelectTrigger>
          <SelectContent>
            {roleOptions.map((o) => (
              <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      )}

      {showSearch && onSearchChange && (
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
          <Input
            placeholder="بحث..."
            value={search || ""}
            onChange={(e) => onSearchChange(e.target.value)}
            className="pl-9"
          />
        </div>
      )}
    </div>
  );
}
