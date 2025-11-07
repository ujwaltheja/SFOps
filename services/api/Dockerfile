# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY turbo.json ./
COPY services/api/package*.json ./services/api/
COPY packages/ ./packages/

# Install dependencies
RUN npm ci

# Copy source code
COPY services/api/ ./services/api/

# Build
RUN npm run build --workspace=@sfops/api

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install production dependencies only
COPY package*.json ./
COPY services/api/package*.json ./services/api/
RUN npm ci --production --workspace=@sfops/api

# Copy built application
COPY --from=builder /app/services/api/dist ./services/api/dist
COPY --from=builder /app/packages ./packages

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

EXPOSE 3000

CMD ["node", "services/api/dist/index.js"]
