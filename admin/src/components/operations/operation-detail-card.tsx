"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { StatusBadge } from "./status-badge";
import { PriorityBadge } from "./priority-badge";
import { UserBadge } from "./user-badge";
import { ActivityTimeline } from "./activity-timeline";
import { format } from "date-fns";
import { ar } from "date-fns/locale";
import { X } from "lucide-react";

interface DetailItem {
  id: string;
  title: string;
  subtitle: string;
  status: string;
  priority?: string;
  role?: string;
  plan?: string;
  createdAt: string;
  relatedEntityType?: string;
  relatedEntityId?: string;
  message?: string;
  phone?: string;
  code?: string;
}

export function OperationDetailCard({
  item,
  onClose,
  actions,
}: {
  item: DetailItem;
  onClose: () => void;
  actions?: React.ReactNode;
}) {
  const entityType = item.relatedEntityType || "unknown";
  const entityId = item.relatedEntityId || item.id;

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between">
          <div className="space-y-1">
            <CardTitle className="text-lg">{item.title}</CardTitle>
            <p className="text-sm text-muted-foreground">{item.subtitle}</p>
          </div>
          <Button variant="ghost" size="icon" onClick={onClose}>
            <X className="size-4" />
          </Button>
        </div>
        <div className="flex items-center gap-2 flex-wrap mt-2">
          <StatusBadge status={item.status} />
          {item.priority && <PriorityBadge priority={item.priority} />}
          {item.role && <UserBadge role={item.role} plan={item.plan} />}
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {item.phone && (
          <div>
            <span className="text-xs text-muted-foreground">الهاتف:</span>
            <p className="font-mono text-sm">{item.phone}</p>
          </div>
        )}
        {item.code && (
          <div>
            <span className="text-xs text-muted-foreground">الكود:</span>
            <p className="font-mono text-lg font-bold text-primary">{item.code}</p>
          </div>
        )}
        {item.message && (
          <div>
            <span className="text-xs text-muted-foreground">المحتوى:</span>
            <p className="text-sm mt-1 whitespace-pre-wrap">{item.message}</p>
          </div>
        )}
        <div>
          <span className="text-xs text-muted-foreground">
            {format(new Date(item.createdAt), "dd MMM yyyy HH:mm", { locale: ar })}
          </span>
        </div>

        {actions && <div className="flex gap-2 flex-wrap">{actions}</div>}

        {entityType !== "unknown" && entityId && (
          <div>
            <span className="text-xs text-muted-foreground block mb-2">السجل الزمني:</span>
            <ActivityTimeline entityType={entityType} entityId={entityId} />
          </div>
        )}
      </CardContent>
    </Card>
  );
}
