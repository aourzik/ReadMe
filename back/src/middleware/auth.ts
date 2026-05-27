import { Elysia } from "elysia";
import { jwt } from "@elysiajs/jwt";

export const jwtPlugin = new Elysia({ name: "jwt" }).use(
  jwt({
    name: "jwt",
    secret: process.env.JWT_SECRET || "readme-secret-change-in-prod",
    exp: "7d",
  })
);

export const authMiddleware = () =>
  new Elysia()
    .use(jwtPlugin)
    .derive({ as: 'scoped' }, async ({ jwt, headers, set }) => {
      const auth = headers["authorization"];
      if (!auth?.startsWith("Bearer ")) {
        set.status = 401;
        throw new Error("Non authentifié");
      }
      const token = auth.slice(7);
      const payload = await jwt.verify(token);
      if (!payload) {
        set.status = 401;
        throw new Error("Token invalide");
      }
      const userId = (payload as any).uid as string;
      if (!userId) {
        set.status = 401;
        throw new Error("Token invalide");
      }
      return { userId };
    });
