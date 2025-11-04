'use client'
import styles from "./page.module.css";
import { HomeContent } from "@/components/HomeContent";

export default function Home() {
  if (process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF) {
    return <HomeContent />;
  }

  return (
    <div className={styles.page}>
      <main className={styles.main}>
        <p>Public version - secret stuff not included</p>
      </main>
    </div>
  );
}
