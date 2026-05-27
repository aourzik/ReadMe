import { Elysia, t } from "elysia";
import bcrypt from "bcryptjs";
import { jwtPlugin } from "../middleware/auth";
import { prisma } from "../utils/prisma";

export const authRoutes = new Elysia({ prefix: "/auth" })
  .use(jwtPlugin)

  // ── POST /api/auth/register ───────────────────────────────────
  .post(
    "/register",
    async ({ body, jwt, set }) => {
      const { name, email, password } = body;

      const existing = await prisma.user.findUnique({ where: { email } });
      if (existing) {
        set.status = 409;
        throw new Error("Email déjà utilisé");
      }

      const passwordHash = await bcrypt.hash(password, 12);
      const handle = email.split("@")[0].replace(/[^a-z0-9_]/gi, "").toLowerCase();

      const user = await prisma.user.create({
        data: { name, email, passwordHash, handle },
      });

      const token = await jwt.sign({ uid: user.id, email: user.email });

      return {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          handle: user.handle,
        },
      };
    },
    {
      body: t.Object({
        name: t.String({ minLength: 2 }),
        email: t.String({ format: "email" }),
        password: t.String({ minLength: 8 }),
      }),
    }
  )

  // ── POST /api/auth/login ──────────────────────────────────────
  .post(
    "/login",
    async ({ body, jwt, set }) => {
      const { email, password } = body;

      const user = await prisma.user.findUnique({ where: { email } });
      if (!user) {
        set.status = 401;
        throw new Error("Identifiants incorrects");
      }

      const valid = await bcrypt.compare(password, user.passwordHash);
      if (!valid) {
        set.status = 401;
        throw new Error("Identifiants incorrects");
      }

      const token = await jwt.sign({ uid: user.id, email: user.email });

      return {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          handle: user.handle,
          avatarUrl: user.avatarUrl,
          readingGoal: user.readingGoal,
          booksReadThisYear: user.booksReadThisYear,
        },
      };
    },
    {
      body: t.Object({
        email: t.String({ format: "email" }),
        password: t.String(),
      }),
    }
  );
