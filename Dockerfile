FROM mcr.microsoft.com/playwright:v1.39.0-jammy

WORKDIR /app

ENV CI=true
ENV HOME=/app
ENV NPM_CONFIG_CACHE=/app/.npm
ENV XDG_CONFIG_HOME=/app/.config

# Copy dependency manifests first so this layer can be cached.
COPY package.json package-lock.json ./

# Install dependencies as root during image build.
RUN npm ci

# Copy application source.
COPY . .

# Jenkins runs the container as UID 122:125.
# Make the application and npm cache writable by that user.
RUN mkdir -p /app/.npm /app/.config \
    && chown -R 122:125 /app

# Netlify CLI, if required, should be declared in package.json
# devDependencies rather than installed globally.