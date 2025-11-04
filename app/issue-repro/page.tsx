"use client";

import { SecretComponent } from "@/components/SecretComponent";

// This page uses the CORRECT pattern - route-level check
// SecretComponent should be fully tree-shaken when env var is not set
export default function IssueReproPage() {
  if (process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF) {
    return <SecretComponent />;
  }

  return <div>Public page</div>;
}
