FROM mcr.microsoft.com/playwright:v1.39.0-jammy

WORKDIR /app

ENV CI=true
ENV HOME=/app
ENV XDG_CONFIG_HOME=/app/.config

# Copy dependency manifests first.
# Docker can cache npm ci when package-lock.json hasn't changed.
COPY package.json package-lock.json ./

# Install all project dependencies.
RUN npm ci

# Copy the application source.
COPY . .

# Netlify CLI should be in package.json devDependencies.