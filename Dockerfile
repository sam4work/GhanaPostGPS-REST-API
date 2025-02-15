# syntax=docker/dockerfile:1.6

# 1️⃣ Base stage: Use official Go image for building
ARG GO_VERSION=1.22
FROM golang:${GO_VERSION}-bookworm AS builder

# Set up working directory
WORKDIR /app

# Copy Go module files first to leverage Docker caching
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copy the entire application source
COPY . .

# Set build arguments for cross-platform support
ARG TARGETOS=$TARGETARCH

# Enable deterministic builds
ENV CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH

# Compile the application with optimizations and security flags
RUN go build -trimpath -ldflags "-s -w" -o /server .

# 2️⃣ Final stage: Minimal secure runtime image
FROM gcr.io/distroless/static:nonroot AS final

# Set non-root user for security
USER nonroot:nonroot

# Set working directory
WORKDIR /app

# Copy the prebuilt binary from builder stage
COPY --from=builder /server /server

# Copy templates & static files for HTML rendering
COPY --from=builder /app/templates /app/templates
COPY --from=builder /app/static /app/static

# Expose the required port
EXPOSE 9091

# Use a non-root user and execute the binary
ENTRYPOINT [ "/server" ]
