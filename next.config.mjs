import { withContentlayer } from "next-contentlayer"

import "./env.mjs"

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  reactStrictMode: true,
  images: {
    domains: ["avatars.githubusercontent.com"],
  },
  experimental: {
    appDir: true,
    serverComponentsExternalPackages: ["@prisma/client"],
  },
}

export default withContentlayer(nextConfig)
