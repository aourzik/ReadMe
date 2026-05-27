import { Elysia } from "elysia";
import { cors } from "@elysiajs/cors";
import { swagger } from "@elysiajs/swagger";
import { authRoutes } from "./routes/auth";
import { bookRoutes } from "./routes/books";
import { loanRoutes } from "./routes/loans";
import { friendRoutes } from "./routes/friends";
import { userRoutes } from "./routes/users";

const app = new Elysia()
  .use(cors({
    origin: ["http://localhost:8080", "http://localhost:3001"],
    methods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  }))
  .use(swagger({
    documentation: {
      info: { title: "ReadMe API", version: "1.0.0" },
    },
  }))
  .get("/health", () => ({ status: "ok", timestamp: new Date().toISOString() }))
  .group("/api", (app) =>
    app
      .use(authRoutes)
      .use(bookRoutes)
      .use(loanRoutes)
      .use(friendRoutes)
      .use(userRoutes)
  )
  .listen(process.env.PORT || 3000);

console.log(`🦊 ReadMe API démarrée sur http://localhost:${app.server?.port}`);

export type App = typeof app;
