import { assertPrune } from "@/lib/assertPrune";

export function SecretStuff() {
  assertPrune();

  return (
    <div>
      <h1>This is secret content</h1>
      <p>This component should be tree-shaken when NEXT_PUBLIC_INCLUDE_SECRET_STUFF is not set</p>
    </div>
  );
}

