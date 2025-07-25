# syntax=docker.io/docker/dockerfile:1

FROM node:24-alpine AS base

# Step 1. Rebuild the source code only when needed
FROM base AS builder

WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json package-lock.json* ./
# Omit --production flag for TypeScript devDependencies
RUN npm ci

COPY src ./src
COPY public ./public
COPY .storybook ./.storybook
COPY tsconfig.json postcss.config.cjs .prettierrc.json .prettierignore .eslintrc.cjs .eslintignore ./
COPY nextDockerCompose.config.mjs ./next.config.mjs


# Environment variables must be present at build time
# https://github.com/vercel/next.js/discussions/14030
# ARG ENV_VARIABLE
# ENV ENV_VARIABLE=${ENV_VARIABLE}
ARG NEXT_PUBLIC_BACKEND_URL
ARG NEXT_PUBLIC_FARO_URL
ARG NEXT_PUBLIC_OTEL_ENVIRONMENT
ARG NEXT_PUBLIC_FARO_SERVICE_NAME
ENV NEXT_PUBLIC_BACKEND_URL=${NEXT_PUBLIC_BACKEND_URL}
ENV NEXT_PUBLIC_FARO_URL=${NEXT_PUBLIC_FARO_URL}
ENV NEXT_PUBLIC_OTEL_ENVIRONMENT=${NEXT_PUBLIC_OTEL_ENVIRONMENT}
ENV NEXT_PUBLIC_FARO_SERVICE_NAME=${NEXT_PUBLIC_FARO_SERVICE_NAME}

# Next.js collects completely anonymous telemetry data about general usage. Learn more here: https://nextjs.org/telemetry
# Uncomment the following line to disable telemetry at build time
ENV NEXT_TELEMETRY_DISABLED=1

# Build Next.js based on the preferred package manager
RUN npm run build

# Note: It is not necessary to add an intermediate step that does a full copy of `node_modules` here

# Step 2. Production image, copy all the files and run next
FROM base AS runner

WORKDIR /app

# Don't run production as root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

COPY --from=builder /app/public ./public

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Environment variables may be redefined at run time
# but right now, while building the image, we assign
# them default values from ARGs for NEXT_PUBLIC_ vars
# they shouldn't really need to be overridden at run time.
# Also see:
# https://github.com/vercel/next.js/discussions/14030
ARG NEXT_PUBLIC_BACKEND_URL
ARG NEXT_PUBLIC_FARO_URL
ARG NEXT_PUBLIC_OTEL_ENVIRONMENT
ARG NEXT_PUBLIC_FARO_SERVICE_NAME
ENV NEXT_PUBLIC_BACKEND_URL=${NEXT_PUBLIC_BACKEND_URL}
ENV NEXT_PUBLIC_FARO_URL=${NEXT_PUBLIC_FARO_URL}
ENV NEXT_PUBLIC_OTEL_ENVIRONMENT=${NEXT_PUBLIC_OTEL_ENVIRONMENT}
ENV NEXT_PUBLIC_FARO_SERVICE_NAME=${NEXT_PUBLIC_FARO_SERVICE_NAME}

# Uncomment the following line to disable telemetry at run time
# ENV NEXT_TELEMETRY_DISABLED 1

# Note: Don't expose ports here, Compose will handle that for us

CMD ["node", "server.js"]