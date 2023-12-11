# Thanks @yordis on Github! https://github.com/vercel/next.js/discussions/16995#discussioncomment-132339

# Install dependencies only when needed
FROM node:lts-alpine AS deps

RUN apk add --no-cache wget

WORKDIR /opt/app
RUN wget https://raw.githubusercontent.com/zyachel/libremdb/main/package.json
RUN wget https://raw.githubusercontent.com/zyachel/libremdb/main/pnpm-lock.yaml
RUN npm install -g pnpm
RUN pnpm install --no-frozen-lockfile

# Rebuild the source code only when needed
# This is where because may be the case that you would try
# to build the app based on some `X_TAG` in my case (Git commit hash)
# but the code hasn't changed.
FROM node:lts-alpine AS builder

RUN apk add --no-cache git

ENV NODE_ENV=production
WORKDIR /opt/app
RUN npm install -g pnpm
RUN git clone https://github.com/zyachel/libremdb.git ./
COPY --from=deps /opt/app/node_modules ./node_modules
RUN pnpm build

# Production image, copy all the files and run next
FROM gcr.io/distroless/nodejs18-debian11 AS runner
ARG X_TAG
WORKDIR /opt/app
ENV NODE_ENV=production
COPY --from=builder /opt/app/next.config.mjs ./
COPY --from=builder /opt/app/public ./public
COPY --from=builder /opt/app/.next ./.next
COPY --from=builder /opt/app/node_modules ./node_modules
ENV HOST=0.0.0.0
ENV PORT=3000
CMD ["./node_modules/next/dist/bin/next", "start"]