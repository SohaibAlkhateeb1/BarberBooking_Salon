"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function PasswordResetsRedirect() {
  const router = useRouter();
  useEffect(() => {
    router.replace("/dashboard/operations?tab=passwordResets");
  }, [router]);
  return null;
}
