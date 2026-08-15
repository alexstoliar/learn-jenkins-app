# ============================================================
# Base Node image
# ============================================================

FROM node:22-bookworm AS node-base

WORKDIR /app

ENV CI=true

# Copy dependency manifests first.
# This allows Docker to cache npm ci as long as the lockfile
# hasn't changed.
COPY package.json package-lock.json ./

RUN npm ci


# ============================================================
# CI image
#
# Used for:
#   - Build
#   - Unit tests
#   - Netlify staging deployment
#   - Netlify production deployment
#
# ============================================================

FROM node-base AS ci

# Install deployment tools once.
RUN npm install --no-save netlify-cli

ENV HOME=/app
ENV XDG_CONFIG_HOME=/app/.config

# Copy application source after dependencies.
COPY . .

RUN mkdir -p /app/.config


# ============================================================
# Playwright CI image
#
# Used for:
#   - Local E2E tests
#   - Staging E2E tests
#   - Production E2E tests
#
# ============================================================

FROM mcr.microsoft.com/playwright:v1.39.0-jammy AS playwright

WORKDIR /app

ENV CI=true

# Copy dependency manifests first.
COPY package.json package-lock.json ./

# Install project dependencies.
RUN npm ci

# Copy application files.
COPY . .