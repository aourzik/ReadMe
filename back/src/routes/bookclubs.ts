import { Elysia, t } from "elysia";
import { authMiddleware } from "../middleware/auth";
import { prisma } from "../utils/prisma";

export const bookClubRoutes = new Elysia({ prefix: "/bookclubs" })
  .use(authMiddleware())

  // GET /api/bookclubs — mes book clubs
  .get("/", async ({ userId }) => {
    const memberships = await prisma.bookClubMember.findMany({
      where: { userId },
      include: {
        club: {
          include: {
            createdBy: true,
            members: { include: { user: true } },
            meetings: { orderBy: { date: "asc" } },
          },
        },
      },
    });
    return memberships.map((m) => serializeClub(m.club));
  })

  // POST /api/bookclubs — créer un book club
  .post("/", async ({ userId, body }) => {
    const club = await prisma.bookClub.create({
      data: {
        name: body.name,
        theme: body.theme,
        createdById: userId,
        members: {
          create: [
            { userId }, // le créateur est automatiquement membre
            ...(body.memberIds ?? [])
              .filter((id: string) => id !== userId)
              .map((id: string) => ({ userId: id })),
          ],
        },
      },
      include: {
        createdBy: true,
        members: { include: { user: true } },
        meetings: true,
      },
    });
    return serializeClub(club);
  }, {
    body: t.Object({
      name:      t.String(),
      theme:     t.Optional(t.String()),
      memberIds: t.Optional(t.Array(t.String())),
    }),
  })

  // GET /api/bookclubs/:id
  .get("/:id", async ({ userId, params, set }) => {
    const membership = await prisma.bookClubMember.findFirst({
      where: { clubId: params.id, userId },
    });
    if (!membership) { set.status = 403; throw new Error("Accès refusé"); }

    const club = await prisma.bookClub.findUnique({
      where: { id: params.id },
      include: {
        createdBy: true,
        members: { include: { user: true } },
        meetings: { orderBy: { date: "asc" } },
      },
    });
    if (!club) { set.status = 404; throw new Error("Club introuvable"); }
    return serializeClub(club);
  })

  // PATCH /api/bookclubs/:id — modifier nom/thème (créateur seulement)
  .patch("/:id", async ({ userId, params, body, set }) => {
    const club = await prisma.bookClub.findFirst({
      where: { id: params.id, createdById: userId },
    });
    if (!club) { set.status = 403; throw new Error("Seul le créateur peut modifier"); }

    const updated = await prisma.bookClub.update({
      where: { id: params.id },
      data: { name: body.name, theme: body.theme },
      include: {
        createdBy: true,
        members: { include: { user: true } },
        meetings: { orderBy: { date: "asc" } },
      },
    });
    return serializeClub(updated);
  }, {
    body: t.Object({
      name:  t.Optional(t.String()),
      theme: t.Optional(t.String()),
    }),
  })

  // POST /api/bookclubs/:id/members — ajouter des membres
  .post("/:id/members", async ({ userId, params, body, set }) => {
    const membership = await prisma.bookClubMember.findFirst({
      where: { clubId: params.id, userId },
    });
    if (!membership) { set.status = 403; throw new Error("Accès refusé"); }

    await prisma.bookClubMember.createMany({
      data: body.userIds.map((uid: string) => ({ userId: uid, clubId: params.id })),
      skipDuplicates: true,
    });
    return { added: true };
  }, {
    body: t.Object({ userIds: t.Array(t.String()) }),
  })

  // DELETE /api/bookclubs/:id/members/:memberId — retirer un membre
  .delete("/:id/members/:memberId", async ({ userId, params, set }) => {
    const club = await prisma.bookClub.findFirst({ where: { id: params.id } });
    if (!club) { set.status = 404; throw new Error("Club introuvable"); }

    // Seul le créateur peut retirer quelqu'un d'autre ; un membre peut se retirer lui-même
    if (params.memberId !== userId && club.createdById !== userId) {
      set.status = 403; throw new Error("Non autorisé");
    }
    await prisma.bookClubMember.deleteMany({
      where: { clubId: params.id, userId: params.memberId },
    });
    return { removed: true };
  })

  // POST /api/bookclubs/:id/meetings — ajouter une date de réunion
  .post("/:id/meetings", async ({ userId, params, body, set }) => {
    const membership = await prisma.bookClubMember.findFirst({
      where: { clubId: params.id, userId },
    });
    if (!membership) { set.status = 403; throw new Error("Accès refusé"); }

    const meeting = await prisma.bookClubMeeting.create({
      data: { clubId: params.id, date: new Date(body.date) },
    });
    return { id: meeting.id, date: meeting.date.toISOString() };
  }, {
    body: t.Object({ date: t.String() }),
  })

  // DELETE /api/bookclubs/:id/meetings/:meetingId
  .delete("/:id/meetings/:meetingId", async ({ userId, params, set }) => {
    const membership = await prisma.bookClubMember.findFirst({
      where: { clubId: params.id, userId },
    });
    if (!membership) { set.status = 403; throw new Error("Accès refusé"); }

    await prisma.bookClubMeeting.delete({ where: { id: params.meetingId } });
    return { deleted: true };
  });

function serializeClub(club: any) {
  return {
    id:        club.id,
    name:      club.name,
    theme:     club.theme,
    createdAt: club.createdAt.toISOString(),
    createdBy: {
      id:   club.createdBy.id,
      name: club.createdBy.name,
      handle: club.createdBy.handle,
    },
    members: club.members.map((m: any) => ({
      id:       m.user.id,
      name:     m.user.name,
      handle:   m.user.handle,
      avatarUrl:m.user.avatarUrl,
      joinedAt: m.joinedAt.toISOString(),
    })),
    meetings: club.meetings.map((m: any) => ({
      id:   m.id,
      date: m.date.toISOString(),
    })),
  };
}
