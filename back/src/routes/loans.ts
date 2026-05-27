import { Elysia, t } from "elysia";
import { authMiddleware } from "../middleware/auth";
import { prisma } from "../utils/prisma";

export const loanRoutes = new Elysia({ prefix: "/loans" })
  .use(authMiddleware())

  // GET /api/loans
  .get("/", async ({ userId, query }) => {
    const where: any = {
      OR: [{ giverId: userId }, { receiverId: userId }],
      returned: false,
    };
    if (query.direction) {
      where.direction = query.direction.toUpperCase();
      if (query.direction === "out") { where.OR = undefined; where.giverId = userId; }
      if (query.direction === "in")  { where.OR = undefined; where.receiverId = userId; }
    }

    const loans = await prisma.loan.findMany({
      where,
      include: { book: true, giver: true, receiver: true },
      orderBy: { since: "desc" },
    });

    return loans.map((l) => ({
      id:        l.id,
      direction: l.giverId === userId ? "out" : "in",
      since:     l.since.toISOString(),
      dueDate:   l.dueDate?.toISOString(),
      returned:  l.returned,
      book:      serializeBook(l.book),
      partner:   serializeUser(l.giverId === userId ? l.receiver : l.giver),
    }));
  }, {
    query: t.Object({ direction: t.Optional(t.String()) }),
  })

  // POST /api/loans
  .post("/", async ({ userId, body, set }) => {
    // Vérifier que le livre appartient à l'utilisateur
    const book = await prisma.book.findFirst({
      where: { id: body.bookId, userId },
    });
    if (!book) { set.status = 404; throw new Error("Livre introuvable"); }

    const loan = await prisma.loan.create({
      data: {
        bookId:     body.bookId,
        giverId:    userId,
        receiverId: body.partnerId,
        direction:  "OUT",
        dueDate:    body.dueDate ? new Date(body.dueDate) : null,
      },
      include: { book: true, giver: true, receiver: true },
    });

    // Marquer le livre comme prêté
    await prisma.book.update({
      where: { id: body.bookId },
      data: { status: "READING" }, // ou custom field lentTo
    });

    return {
      id:        loan.id,
      direction: "out",
      since:     loan.since.toISOString(),
      dueDate:   loan.dueDate?.toISOString(),
      book:      serializeBook(loan.book),
      partner:   serializeUser(loan.receiver),
    };
  }, {
    body: t.Object({
      bookId:    t.String(),
      partnerId: t.String(),
      dueDate:   t.Optional(t.String()),
    }),
  })

  // PATCH /api/loans/:id/return
  .patch("/:id/return", async ({ userId, params, set }) => {
    const loan = await prisma.loan.findFirst({
      where: {
        id: params.id,
        OR: [{ giverId: userId }, { receiverId: userId }],
      },
    });
    if (!loan) { set.status = 404; throw new Error("Prêt introuvable"); }

    await prisma.loan.update({
      where: { id: params.id },
      data: { returned: true, returnedAt: new Date() },
    });

    return { returned: true };
  });

function serializeBook(book: any) {
  return {
    id: book.id, title: book.title, author: book.author,
    year: book.year, pages: book.pages, coverUrl: book.coverUrl,
    tags: book.tags, rating: book.rating, description: book.description,
  };
}
function serializeUser(user: any) {
  return { id: user.id, name: user.name, handle: user.handle, avatarUrl: user.avatarUrl };
}
