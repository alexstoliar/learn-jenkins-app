# ============================================================
# Base image
# ============================================================
# Playwright image gives us:
# - Node.js
# - npm
# - Playwright
# - Chromium / Firefox / WebKit
# - all required browser dependencies
#
# We upgrade Node.js to 22 because current Netlify CLI
# requires a newer Node version than the old Playwright image.
# ============================================================

FROM mcr.microsoft.com/playwright:v1.39.0-jammy

WORKDIR /app

ENV CI=true
ENV HOME=/app
ENV NPM_CONFIG_CACHE=/app/.npm
ENV XDG_CONFIG_HOME=/app/.config

# ============================================================
# Upgrade Node.js
# ============================================================

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# Verify runtime
RUN node --version \
    && npm --version \
    && npx playwright --version

# ============================================================
# Install project dependencies
# ============================================================

# Copy dependency files first.
# Docker can reuse this layer when package-lock.json
# hasn't changed.
COPY package.json package-lock.json ./

RUN npm ci

# ============================================================
# Copy application
# ============================================================

COPY . .

# ============================================================
# Permissions
# ============================================================

# Jenkins Docker Pipeline runs the container as the Jenkins
# user (in your environment UID 122 / GID 125).
#
# Make the application, npm cache and config directories
# writable by Jenkins.
RUN mkdir -p \
        /app/.npm \
        /app/.config \
    && chown -R 122:125 /app

# ============================================================
# Final verification
# ============================================================

RUN node --version \
    && npm --version \
    && npx playwright --version \
    && npx netlify --version