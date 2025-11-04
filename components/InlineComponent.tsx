import { assertPrune } from "@/lib/assertPrune";

export function InlineComponent() {
  // This assertPrune call is INLINE within a component
  // Without a route-level check, this WON'T be tree-shaken
  assertPrune();

  return (
    <div>
      <h2>Inline Component with assertPrune</h2>
      <p>This component calls assertPrune() inline at the top of the function</p>
    </div>
  );
}
