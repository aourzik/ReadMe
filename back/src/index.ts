import { Elysia } from "elysia";
import { cors } from "@elysiajs/cors";
import { swagger } from "@elysiajs/swagger";
import { authRoutes } from "./routes/auth";
import { bookRoutes } from "./routes/books";
import { loanRoutes } from "./routes/loans";
import { friendRoutes } from "./routes/friends";
import { userRoutes } from "./routes/users";
import { bookClubRoutes } from "./routes/bookclubs";
import { messageRoutes } from "./routes/messages";
import { notificationRoutes } from "./routes/notifications";

const app = new Elysia()
  .use(cors({
    origin: (process.env.CORS_ORIGINS ?? "http://localhost:8080,http://localhost:3001")
      .split(",")
      .map((o) => o.trim()),
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
      .use(bookClubRoutes)
      .use(messageRoutes)
      .use(notificationRoutes)
  )
  .listen(process.env.PORT || 3000);

console.log(`🦊 ReadMe API démarrée sur http://localhost:${app.server?.port}`);

export type App = typeof app;
