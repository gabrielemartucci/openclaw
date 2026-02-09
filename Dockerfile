# Stage 1 — build
FROM node:20-bookworm-slim AS builder
ENV PNPM_HOME="/usr/local/share/pnpm" \
PATH="$PNPM_HOME:$PATH" \
NODE_ENV=production
RUN corepack enable

# sistemi minimi per build (git, python, make, ecc.)
RUN apt-get update && \
apt-get install -y --no-install-recommends \
git python3 build-essential ca-certificates && \
rm -rf /var/lib/apt/lists/*

WORKDIR /app

# solo i file necessari per installare le dipendenze
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

# copia del resto del progetto
COPY . .

# evita build UI superflua (puoi rimetterla se ti serve)
ENV OPENCLAW_A2UI_SKIP_MISSING=1
RUN pnpm build

# teniamo solo le dipendenze runtime
RUN pnpm prune --prod

# Stage 2 — runtime leggero
FROM node:20-bookworm-slim AS runtime
ENV PNPM_HOME="/usr/local/share/pnpm" \
PATH="$PNPM_HOME:$PATH" \
NODE_ENV=production
RUN corepack enable

WORKDIR /app
COPY --from=builder /app /app

# l’utente node esiste già nell’immagine slim
USER node
CMD ["./scripts/run.sh"]
