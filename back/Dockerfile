FROM oven/bun:1.1 AS base
WORKDIR /app

COPY package.json bun.lockb* ./
RUN bun install --frozen-lockfile

COPY . .
RUN bunx prisma generate

EXPOSE 3000

CMD ["sh", "-c", "bunx prisma db push && bun run --watch src/index.ts"]
