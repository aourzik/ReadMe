import { Elysia, t } from "elysia";
import { authMiddleware } from "../middleware/auth";
import { prisma } from "../utils/prisma";

export const friendRoutes = new Elysia({ prefix: "/friends" })
  .use(authMiddleware())

  // GET /api/friends
  .get("/", async ({ userId }) => {
    const friendships = await prisma.friendship.findMany({
      where: { OR: [{ userAId: userId }, { userBId: userId }] },
      include: { userA: true, userB: true },
    });
    return friendships.map((f) => {
      const friend = f.userAId === userId ? f.userB : f.userA;
      return serializeUser(friend);
    });
  })

  // GET /api/friends/requests
  .get("/requests", async ({ userId }) => {
    const requests = await prisma.friendRequest.findMany({
      where: { receiverId: userId, status: "PENDING" },
      include: { sender: true },
    });
    return requests.map((r) => ({
      id: r.id,
      sender: serializeUser(r.sender),
      sentAt: r.createdAt.toISOString(),
      status: r.status.toLowerCase(),
    }));
  })

  // POST /api/friends/request
  .post("/request", async ({ userId, body, set }) => {
    // Vérifier pas déjà amis
    const existing = await prisma.friendship.findFirst({
      where: {
        OR: [
          { userAId: userId, userBId: body.userId },
          { userAId: body.userId, userBId: userId },
        ],
      },
    });
    if (existing) { set.status = 409; throw new Error("Déjà amis"); }

    const request = await prisma.friendRequest.create({
      data: { senderId: userId, receiverId: body.userId },
      include: { sender: true },
    });
    return { id: request.id, status: "pending" };
  }, {
    body: t.Object({ userId: t.String() }),
  })

  // PATCH /api/friends/requests/:id/accept
  .patch("/requests/:id/accept", async ({ userId, params, set }) => {
    const request = await prisma.friendRequest.findFirst({
      where: { id: params.id, receiverId: userId, status: "PENDING" },
    });
    if (!request) { set.status = 404; throw new Error("Demande introuvable"); }

    await prisma.$transaction([
      prisma.friendRequest.update({
        where: { id: params.id },
        data: { status: "ACCEPTED" },
      }),
      prisma.friendship.create({
        data: { userAId: request.senderId, userBId: userId },
      }),
    ]);

    return { accepted: true };
  })

  // GET /api/friends/:userId/books
  .get("/:userId/books", async ({ userId, params }) => {
    // Vérifier qu'ils sont amis
    const friendship = await prisma.friendship.findFirst({
      where: {
        OR: [
          { userAId: userId, userBId: params.userId },
          { userAId: params.userId, userBId: userId },
        ],
      },
    });
    if (!friendship) return []; // Pas amis = liste vide

    const books = await prisma.book.findMany({
      where: { userId: params.userId },
      orderBy: { addedAt: "desc" },
    });
    return books.map((b) => ({
      id: b.id, title: b.title, author: b.author, year: b.year,
      pages: b.pages, coverUrl: b.coverUrl, tags: b.tags,
      rating: b.rating, description: b.description,
      status: b.status.toLowerCase(),
    }));
  });

function serializeUser(user: any) {
  return {
    id: user.id, name: user.name, email: user.email,
    handle: user.handle, avatarUrl: user.avatarUrl,
    bookCount: 0, friendCount: 0,
    favoriteGenres: [],
  };
}
