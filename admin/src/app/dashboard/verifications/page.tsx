"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function VerificationsRedirect() {
  const router = useRouter();
  useEffect(() => {
    router.replace("/dashboard/operations?tab=verifications");
  }, [router]);
  return null;
}
