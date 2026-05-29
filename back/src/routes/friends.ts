import { Elysia, t } from "elysia";
import { authMiddleware } from "../middleware/auth";
import { prisma } from "../utils/prisma";

export const friendRoutes = new Elysia({ prefix: "/friends" })
  .use(authMiddleware())

  // GET /api/friends
  .get("/", async ({ userId }) => {
    const friendships = await prisma.friendship.findMany({
      where: { OR: [{ userAId: userId }, { userBId: userId }] },
      include: {
        userA: { include: { _count: { select: { books: true, friendshipsA: true, friendshipsB: true } } } },
        userB: { include: { _count: { select: { books: true, friendshipsA: true, friendshipsB: true } } } },
      },
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

  // GET /api/friends/activity — activité récente des amis
  .get("/activity", async ({ userId }) => {
    const friendships = await prisma.friendship.findMany({
      where: { OR: [{ userAId: userId }, { userBId: userId }] },
    });
    const friendIds = friendships.map((f) =>
      f.userAId === userId ? f.userBId : f.userAId
    );
    if (friendIds.length === 0) return [];

    const activities = await prisma.activity.findMany({
      where: { userId: { in: friendIds } },
      include: {
        user: true,
        book: true,
      },
      orderBy: { createdAt: "desc" },
      take: 30,
    });

    return activities
      .filter((a) => a.book !== null)
      .map((a) => ({
        id: a.id,
        type: a.type.toLowerCase(),
        createdAt: a.createdAt.toISOString(),
        user: { id: a.user.id, name: a.user.name, handle: a.user.handle, avatarUrl: a.user.avatarUrl },
        book: a.book ? {
          id: a.book.id,
          title: a.book.title,
          author: a.book.author,
          coverUrl: a.book.coverUrl,
          year: a.book.year,
          googleBooksId: a.book.googleBooksId,
        } : null,
      }));
  })

  // POST /api/friends/request
  .post("/request", async ({ userId, body, set }) => {
    const existing = await prisma.friendship.findFirst({
      where: {
        OR: [
          { userAId: userId, userBId: body.userId },
          { userAId: body.userId, userBId: userId },
        ],
      },
    });
    if (existing) { set.status = 409; throw new Error("Déjà amis"); }

    const alreadySent = await prisma.friendRequest.findFirst({
      where: { senderId: userId, receiverId: body.userId, status: "PENDING" },
    });
    if (alreadySent) { set.status = 409; throw new Error("Demande déjà envoyée"); }

    const request = await prisma.friendRequest.create({
      data: { senderId: userId, receiverId: body.userId },
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

  // PATCH /api/friends/requests/:id/decline
  .patch("/requests/:id/decline", async ({ userId, params, set }) => {
    const request = await prisma.friendRequest.findFirst({
      where: { id: params.id, receiverId: userId, status: "PENDING" },
    });
    if (!request) { set.status = 404; throw new Error("Demande introuvable"); }

    await prisma.friendRequest.update({
      where: { id: params.id },
      data: { status: "DECLINED" },
    });
    return { declined: true };
  })

  // DELETE /api/friends/:userId — supprimer un ami
  .delete("/:friendId", async ({ userId, params }) => {
    await prisma.friendship.deleteMany({
      where: {
        OR: [
          { userAId: userId, userBId: params.friendId },
          { userAId: params.friendId, userBId: userId },
        ],
      },
    });
    return { removed: true };
  })

  // GET /api/friends/:userId/books
  .get("/:userId/books", async ({ userId, params }) => {
    const friendship = await prisma.friendship.findFirst({
      where: {
        OR: [
          { userAId: userId, userBId: params.userId },
          { userAId: params.userId, userBId: userId },
        ],
      },
    });
    if (!friendship) return [];

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
  const friendCount = (user._count?.friendshipsA ?? 0) + (user._count?.friendshipsB ?? 0);
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    handle: user.handle,
    avatarUrl: user.avatarUrl,
    bookCount: user._count?.books ?? 0,
    friendCount,
    favoriteGenres: [],
  };
}
