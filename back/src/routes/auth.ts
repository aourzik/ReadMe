import { Elysia, t } from "elysia";
import bcrypt from "bcryptjs";
import { jwtPlugin } from "../middleware/auth";
import { prisma } from "../utils/prisma";

async function sendEmail(to: string, code: string) {
  const res = await fetch("https://api.brevo.com/v3/smtp/email", {
    method: "POST",
    headers: {
      "api-key": process.env.BREVO_API_KEY!,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      sender: { name: "ReadMe", email: "a.ourzik.dev@gmail.com" },
      to: [{ email: to }],
      subject: "Ton code ReadMe",
      htmlContent: `
        <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 32px;">
          <h2 style="font-size: 24px; margin-bottom: 8px;">Réinitialise ton mot de passe</h2>
          <p style="color: #666; margin-bottom: 24px;">Voici ton code de réinitialisation. Il est valable <strong>15 minutes</strong>.</p>
          <div style="background: #f5f5f5; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
            <span style="font-size: 40px; font-weight: 700; letter-spacing: 8px; color: #1a1a1a;">${code}</span>
          </div>
          <p style="color: #999; font-size: 13px;">Si tu n'as pas demandé cette réinitialisation, ignore cet email.</p>
        </div>
      `,
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    console.error(`[Brevo] Erreur ${res.status}:`, body);
    throw new Error(`Email non envoyé (${res.status})`);
  }
}

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
        user: { id: user.id, name: user.name, email: user.email, handle: user.handle },
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
  )

  // ── POST /api/auth/forgot-password ────────────────────────────
  .post(
    "/forgot-password",
    async ({ body }) => {
      const { email } = body;

      const user = await prisma.user.findUnique({ where: { email } });

      // On ne révèle pas si l'email existe ou non
      if (!user) return { message: "Si cet email existe, un code t'a été envoyé." };

      // Invalide les anciens tokens
      await prisma.passwordResetToken.updateMany({
        where: { email, used: false },
        data: { used: true },
      });

      // Génère un code à 6 chiffres
      const code = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 min

      await prisma.passwordResetToken.create({
        data: { email, code, expiresAt },
      });

      // Envoie l'email via Brevo
      await sendEmail(email, code);

      return { message: "Si cet email existe, un code t'a été envoyé." };
    },
    {
      body: t.Object({
        email: t.String({ format: "email" }),
      }),
    }
  )

  // ── POST /api/auth/reset-password ─────────────────────────────
  .post(
    "/reset-password",
    async ({ body, set }) => {
      const { email, code, password } = body;

      const token = await prisma.passwordResetToken.findFirst({
        where: {
          email,
          code,
          used: false,
          expiresAt: { gt: new Date() },
        },
      });

      if (!token) {
        set.status = 400;
        throw new Error("Code invalide ou expiré.");
      }

      const passwordHash = await bcrypt.hash(password, 12);

      await prisma.user.update({
        where: { email },
        data: { passwordHash },
      });

      await prisma.passwordResetToken.update({
        where: { id: token.id },
        data: { used: true },
      });

      return { message: "Mot de passe mis à jour avec succès." };
    },
    {
      body: t.Object({
        email: t.String({ format: "email" }),
        code: t.String({ minLength: 6, maxLength: 6 }),
        password: t.String({ minLength: 8 }),
      }),
    }
  );
