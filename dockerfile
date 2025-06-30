# Stage 1: Build environment
FROM debian:bullseye-slim AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    gzip \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for Flutter
RUN useradd -m -s /bin/bash flutteruser

# Install Flutter (specific version)
ARG FLUTTER_VERSION=3.27.3
RUN git clone -b ${FLUTTER_VERSION} --depth 1 https://github.com/flutter/flutter.git /opt/flutter
RUN chown -R flutteruser:flutteruser /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Switch to non-root user
USER flutteruser
WORKDIR /home/flutteruser/flutter_native_bridge

# Pre-download Flutter dependencies to improve build cache
RUN flutter doctor
RUN flutter precache --web

# Copy the entire package (parent directory and example)
COPY --chown=flutteruser:flutteruser . .

# Copy the compression script
COPY --chown=flutteruser:flutteruser compress.sh .
RUN chmod +x compress.sh

# Navigate to the example directory
WORKDIR /home/flutteruser/flutter_native_bridge/example

# Get Flutter dependencies
RUN flutter pub get

# Build the web app
RUN flutter build web --release --web-renderer canvaskit

# Run the compression script
RUN ../compress.sh

# Stage 2: Standard nginx (no additional modules needed)
FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy nginx configuration
COPY nginx-gzip.conf /etc/nginx/nginx.conf

# Copy the built web app and compressed files
COPY --from=builder /home/flutteruser/flutter_native_bridge/example/build/web /usr/share/nginx/html

# Cloud Run expects port 8080
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]