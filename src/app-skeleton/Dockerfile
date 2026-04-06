# Multi-stage placeholder Dockerfile for future application code
# This demonstrates best practices (minimal layers, non-root user)
# Actual application logic will be added in Phase 2+

FROM alpine:3.18 AS base
LABEL maintainer="DevOps Team"
LABEL description="k3s Lab Application Skeleton - Placeholder"

# Install runtime dependencies only (will be customized per app)
RUN apk add --no-cache \
    ca-certificates \
    curl

# Create non-root user for security
RUN addgroup -g 1000 app && \
    adduser -D -u 1000 -G app app

# Set working directory
WORKDIR /app

FROM base AS final
USER app

# Health check template
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Placeholder command - will be overridden by deployment manifests
CMD ["/bin/sh", "-c", "echo 'App skeleton ready. Waiting for actual application code...' && sleep 3600"]
