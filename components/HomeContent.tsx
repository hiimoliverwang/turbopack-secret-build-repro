import { HomeContentInner } from "@/components/HomeContentInner";

export function HomeContent() {
  if (process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF) {
    return <HomeContentInner />;
  }

  return <div>Public version without secret stuff</div>;
}
