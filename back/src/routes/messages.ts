import { Elysia, t } from "elysia";
import { authMiddleware } from "../middleware/auth";
import { prisma } from "../utils/prisma";

export const messageRoutes = new Elysia({ prefix: "/messages" })
  .use(authMiddleware())

  // GET /api/messages — liste des conversations (une par partenaire, dernier message)
  .get("/", async ({ userId }) => {
    const messages = await prisma.message.findMany({
      where: { OR: [{ senderId: userId }, { receiverId: userId }] },
      include: { sender: true, receiver: true },
      orderBy: { createdAt: "desc" },
    });

    // Grouper par partenaire (keep only latest per partner)
    const seen = new Set<string>();
    const convos: any[] = [];
    for (const m of messages) {
      const partnerId = m.senderId === userId ? m.receiverId : m.senderId;
      if (seen.has(partnerId)) continue;
      seen.add(partnerId);
      const partner = m.senderId === userId ? m.receiver : m.sender;
      const unread = await prisma.message.count({
        where: { senderId: partnerId, receiverId: userId, readAt: null },
      });
      convos.push({
        partnerId:   partner.id,
        partnerName: partner.name,
        partnerHandle: partner.handle,
        lastMessage: m.content,
        lastAt:      m.createdAt.toISOString(),
        unread,
      });
    }
    return convos;
  })

  // GET /api/messages/:userId — messages échangés avec un utilisateur
  .get("/:partnerId", async ({ userId, params }) => {
    const messages = await prisma.message.findMany({
      where: {
        OR: [
          { senderId: userId,          receiverId: params.partnerId },
          { senderId: params.partnerId, receiverId: userId },
        ],
      },
      include: { sender: true },
      orderBy: { createdAt: "asc" },
    });

    // Marquer les messages reçus comme lus
    await prisma.message.updateMany({
      where: { senderId: params.partnerId, receiverId: userId, readAt: null },
      data: { readAt: new Date() },
    });

    return messages.map((m) => ({
      id:        m.id,
      content:   m.content,
      createdAt: m.createdAt.toISOString(),
      readAt:    m.readAt?.toISOString(),
      fromMe:    m.senderId === userId,
      senderName: m.sender.name,
    }));
  })

  // POST /api/messages/:userId — envoyer un message
  .post("/:partnerId", async ({ userId, params, body }) => {
    const message = await prisma.message.create({
      data: {
        content:    body.content,
        senderId:   userId,
        receiverId: params.partnerId,
      },
      include: { sender: true },
    });

    // Notifier le destinataire
    await prisma.appNotification.create({
      data: {
        type:       "MESSAGE_RECEIVED",
        userId:     params.partnerId,
        fromUserId: userId,
      },
    });

    return {
      id:        message.id,
      content:   message.content,
      createdAt: message.createdAt.toISOString(),
      readAt:    null,
      fromMe:    true,
      senderName: message.sender.name,
    };
  }, {
    body: t.Object({ content: t.String() }),
  });
