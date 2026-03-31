# ============================================
# Stage 1: Install dependencies
# ============================================
FROM node:18-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json pnpm-lock.yaml ./
COPY prisma ./prisma/

RUN corepack enable pnpm && pnpm install --frozen-lockfile

# ============================================
# Stage 2: Build the application
# ============================================
FROM node:18-alpine AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build-time environment variables
ARG DATABASE_URL
ARG NEXTAUTH_SECRET
ARG NEXT_PUBLIC_APP_URL

ENV DATABASE_URL=${DATABASE_URL}
ENV NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
ENV NEXT_PUBLIC_APP_URL=${NEXT_PUBLIC_APP_URL}
ENV NEXT_TELEMETRY_DISABLED=1

# Generate Prisma client and build contentlayer + Next.js
RUN corepack enable pnpm && \
    npx prisma generate && \
    pnpm build

# ============================================
# Stage 3: Production runner (minimal image)
# ============================================
FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy only what standalone output needs
COPY --from=builder /app/public ./public
COPY --from=builder /app/.contentlayer ./.contentlayer

# standalone output includes minimal server + traced node_modules
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy Prisma engine binaries for runtime migrations
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=builder /app/prisma ./prisma

USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
