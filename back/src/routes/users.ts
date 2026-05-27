import { Elysia, t } from "elysia";
import { authMiddleware } from "../middleware/auth";
import { prisma } from "../utils/prisma";

export const userRoutes = new Elysia({ prefix: "/users" })
  .use(authMiddleware())

  // GET /api/users/me
  .get("/me", async ({ userId }) => {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        _count: {
          select: { books: true, friendshipsA: true, friendshipsB: true },
        },
      },
    });
    if (!user) throw new Error("Utilisateur introuvable");

    return {
      id:               user.id,
      name:             user.name,
      email:            user.email,
      handle:           user.handle,
      avatarUrl:        user.avatarUrl,
      location:         user.location,
      readingGoal:      user.readingGoal,
      booksReadThisYear:user.booksReadThisYear,
      bookCount:        user._count.books,
      friendCount:      user._count.friendshipsA + user._count.friendshipsB,
      favoriteGenres:   [],
    };
  })

  // PATCH /api/users/me
  .patch("/me", async ({ userId, body }) => {
    const user = await prisma.user.update({
      where: { id: userId },
      data: body,
    });
    return { id: user.id, name: user.name, email: user.email, handle: user.handle };
  }, {
    body: t.Object({
      name:        t.Optional(t.String()),
      handle:      t.Optional(t.String()),
      avatarUrl:   t.Optional(t.String()),
      location:    t.Optional(t.String()),
      readingGoal: t.Optional(t.Number()),
    }),
  })

  // GET /api/users/search?q=
  .get("/search", async ({ userId, query }) => {
    if (!query.q || query.q.length < 2) return [];
    const users = await prisma.user.findMany({
      where: {
        AND: [
          { id: { not: userId } },
          {
            OR: [
              { name: { contains: query.q, mode: "insensitive" } },
              { handle: { contains: query.q, mode: "insensitive" } },
              { email: { contains: query.q, mode: "insensitive" } },
            ],
          },
        ],
      },
      take: 20,
    });
    return users.map((u) => ({
      id: u.id, name: u.name, handle: u.handle, avatarUrl: u.avatarUrl,
      bookCount: 0, friendCount: 0,
    }));
  }, {
    query: t.Object({ q: t.Optional(t.String()) }),
  });
