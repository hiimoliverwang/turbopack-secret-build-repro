import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  env: {
    // Explicitly set to empty string when not provided - this enables tree-shaking!
    NEXT_PUBLIC_INCLUDE_SECRET_STUFF: process.env.NEXT_PUBLIC_INCLUDE_SECRET_STUFF || "",
  },
};

export default nextConfig;
