import { Elysia } from "elysia";
import { authMiddleware } from "../middleware/auth";
import { prisma } from "../utils/prisma";

export const notificationRoutes = new Elysia({ prefix: "/notifications" })
  .use(authMiddleware())

  // GET /api/notifications
  .get("/", async ({ userId }) => {
    const notifs = await prisma.appNotification.findMany({
      where: { userId },
      include: { fromUser: true },
      orderBy: { createdAt: "desc" },
      take: 50,
    });

    return notifs.map((n) => ({
      id:            n.id,
      type:          n.type.toLowerCase(),
      createdAt:     n.createdAt.toISOString(),
      read:          n.read,
      loanId:        n.loanId,
      bookTitle:     n.bookTitle,
      fromUserId:    n.fromUserId,
      fromUserName:  n.fromUser.name,
      fromUserHandle: n.fromUser.handle,
    }));
  })

  // GET /api/notifications/unread-count
  .get("/unread-count", async ({ userId }) => {
    const count = await prisma.appNotification.count({
      where: { userId, read: false },
    });
    return { count };
  })

  // PATCH /api/notifications/:id/read
  .patch("/:id/read", async ({ userId, params }) => {
    await prisma.appNotification.updateMany({
      where: { id: params.id, userId },
      data: { read: true },
    });
    return { read: true };
  })

  // PATCH /api/notifications/read-all
  .patch("/read-all", async ({ userId }) => {
    await prisma.appNotification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
    return { done: true };
  });
