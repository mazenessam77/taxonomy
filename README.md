# Taxonomy

An open source application built using the new router, server components and everything new in Next.js 13.

> **Warning**
> This app is a work in progress. I'm building this in public. You can follow the progress on Twitter [@shadcn](https://twitter.com/shadcn).
> See the roadmap below.

## About this project

This project as an experiment to see how a modern app (with features like authentication, subscriptions, API routes, static pages for docs ...etc) would work in Next.js 13 and server components.

**This is not a starter template.**

A few people have asked me to turn this into a starter. I think we could do that once the new features are out of beta.

## Note on Performance

> **Warning**
> This app is using the unstable releases for Next.js 13 and React 18. The new router and app dir is still in beta and not production-ready.
> **Expect some performance hits when testing the dashboard**.
> If you see something broken, you can ping me [@shadcn](https://twitter.com/shadcn).

## Features

- New `/app` dir,
- Routing, Layouts, Nested Layouts and Layout Groups
- Data Fetching, Caching and Mutation
- Loading UI
- Route handlers
- Metadata files
- Server and Client Components
- API Routes and Middlewares
- Authentication using **NextAuth.js**
- ORM using **Prisma**
- Database on **PlanetScale**
- UI Components built using **Radix UI**
- Documentation and blog using **MDX** and **Contentlayer**
- Subscriptions using **Stripe**
- Styled using **Tailwind CSS**
- Validations using **Zod**
- Written in **TypeScript**

## Roadmap

- [x] ~Add MDX support for basic pages~
- [x] ~Build marketing pages~
- [x] ~Subscriptions using Stripe~
- [x] ~Responsive styles~
- [x] ~Add OG image for blog using @vercel/og~
- [x] Dark mode

## Known Issues

A list of things not working right now:

1. ~GitHub authentication (use email)~
2. ~[Prisma: Error: ENOENT: no such file or directory, open '/var/task/.next/server/chunks/schema.prisma'](https://github.com/prisma/prisma/issues/16117)~
3. ~[Next.js 13: Client side navigation does not update head](https://github.com/vercel/next.js/issues/42414)~
4. [Cannot use opengraph-image.tsx inside catch-all routes](https://github.com/vercel/next.js/issues/48162)

## Why not tRPC, Turborepo or X?

I might add this later. For now, I want to see how far we can get using Next.js only.

If you have some suggestions, feel free to create an issue.

## Running Locally

1. Install dependencies using pnpm:

```sh
pnpm install
```

2. Copy `.env.example` to `.env.local` and update the variables.

```sh
cp .env.example .env.local
```

3. Start the development server:

```sh
pnpm dev
```

---

## AWS Production Infrastructure

### High-Availability Architecture

This project is deployed on a professional-grade AWS infrastructure designed for high availability, cost efficiency, and auto-scaling.

```
┌──────────────┐     ┌──────────────┐     ┌─────────────────────────────────────┐
│              │     │              │     │            Amazon EKS                │
│  Route 53    │────▸│  CloudFront  │────▸│  ┌───────────────────────────────┐  │
│  (DNS)       │     │  (CDN)       │     │  │   ALB (Ingress Controller)    │  │
│              │     │              │     │  └───────────┬───────────────────┘  │
└──────────────┘     └──────────────┘     │              │                      │
                                          │  ┌───────────▼───────────────────┐  │
                                          │  │  Taxonomy Pods (Spot Nodes)   │  │
                                          │  │  ┌─────┐ ┌─────┐ ┌─────┐     │  │
                                          │  │  │Pod 1│ │Pod 2│ │Pod N│     │  │
                                          │  │  └──┬──┘ └──┬──┘ └──┬──┘     │  │
                                          │  └─────┼───────┼───────┼────────┘  │
                                          └────────┼───────┼───────┼───────────┘
                                                   │       │       │
                                          ┌────────▼───────▼───────▼───────────┐
                                          │     Amazon RDS (PostgreSQL)        │
                                          │        Private Subnets             │
                                          │     Multi-AZ │ Encrypted           │
                                          └────────────────────────────────────┘
```

### Traffic Flow

1. **Route 53** resolves the domain to the CloudFront distribution.
2. **CloudFront (CDN)** caches static assets (`/_next/static/*`, images) at 400+ edge locations worldwide, dramatically reducing latency for end users. Dynamic API requests are forwarded to the origin.
3. **Application Load Balancer (ALB)** receives traffic from CloudFront, terminates SSL using an ACM certificate, and routes requests to healthy pods using IP-based target groups.
4. **EKS Pods** run the Next.js application in standalone mode. Pods are distributed across multiple Availability Zones via `topologySpreadConstraints`.
5. **Amazon RDS (PostgreSQL)** sits in private subnets with no public access. The database is only reachable from within the VPC, ensuring data security.

### Karpenter & Spot Instance Management

[Karpenter](https://karpenter.sh/) is a Kubernetes-native node autoscaler that replaces the traditional Cluster Autoscaler:

- **Cost Optimization**: Pods are scheduled on EC2 Spot Instances (up to 90% savings vs On-Demand) using `nodeSelector: karpenter.sh/capacity-type: spot`.
- **Intelligent Scaling**: When pods are pending due to insufficient capacity, Karpenter provisions the right-sized node in seconds — not minutes. It selects from a diverse set of instance types to maximize Spot availability.
- **Graceful Interruption Handling**: When AWS reclaims a Spot Instance, Karpenter automatically cordons the node, drains pods gracefully (respecting `terminationGracePeriodSeconds`), and provisions a replacement node.
- **Multi-AZ Resilience**: `topologySpreadConstraints` ensure pods are evenly distributed across Availability Zones, so a single AZ disruption does not take down the application.

### Deployment Pipeline

The CI/CD pipeline (`.github/workflows/deploy.yml`) automates the full deployment:

1. **Build** — Multi-stage Docker build using Next.js standalone output (~100MB final image).
2. **Push** — Image is tagged with the commit SHA and pushed to Amazon ECR.
3. **Deploy** — `kubectl apply` rolls out the new image with zero-downtime rolling updates.

### Key Files

| File | Purpose |
|---|---|
| `Dockerfile` | Multi-stage build optimized for standalone Next.js |
| `k8s/deployment.yaml` | Pod spec with Spot scheduling, probes, and resource limits |
| `k8s/service.yaml` | ClusterIP service exposing port 80 → 3000 |
| `k8s/ingress.yaml` | ALB ingress with SSL termination and health checks |
| `k8s/secrets.yaml` | Template for all application secrets |
| `.github/workflows/deploy.yml` | CI/CD pipeline: Build → ECR → EKS |

---

## License

Licensed under the [MIT license](https://github.com/shadcn/taxonomy/blob/main/LICENSE.md).
