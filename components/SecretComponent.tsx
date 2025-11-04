"use client";

import { assertPrune } from "@/lib/assertPrune";

export function SecretComponent() {
  assertPrune();

  return (
    <div>
      <h1>Secret Content</h1>
      <p>This component should be completely tree-shaken when env var is not set</p>
    </div>
  );
}
