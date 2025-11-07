# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
COPY turbo.json ./
COPY services/workers/package*.json ./services/workers/
COPY packages/ ./packages/

RUN npm ci

COPY services/workers/ ./services/workers/

RUN npm run build --workspace=@sfops/workers

# Production stage
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
COPY services/workers/package*.json ./services/workers/
RUN npm ci --production --workspace=@sfops/workers

COPY --from=builder /app/services/workers/dist ./services/workers/dist
COPY --from=builder /app/packages ./packages

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

CMD ["node", "services/workers/dist/index.js"]
