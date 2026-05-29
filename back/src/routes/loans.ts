import { Elysia, t } from "elysia";
import { authMiddleware } from "../middleware/auth";
import { prisma } from "../utils/prisma";

export const loanRoutes = new Elysia({ prefix: "/loans" })
  .use(authMiddleware())

  // GET /api/loans — seulement les prêts ACTIVE
  .get("/", async ({ userId, query }) => {
    const where: any = {
      OR: [{ giverId: userId }, { receiverId: userId }],
      returned: false,
      status: "ACTIVE",
    };
    if (query.direction === "out") { where.OR = undefined; where.giverId    = userId; }
    if (query.direction === "in")  { where.OR = undefined; where.receiverId = userId; }

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

  // POST /api/loans — prêter un livre directement (giver = toi, status = ACTIVE)
  .post("/", async ({ userId, body, set }) => {
    const book = await prisma.book.findFirst({ where: { id: body.bookId, userId } });
    if (!book) { set.status = 404; throw new Error("Livre introuvable"); }

    const loan = await prisma.loan.create({
      data: {
        bookId:     body.bookId,
        giverId:    userId,
        receiverId: body.partnerId,
        direction:  "OUT",
        status:     "ACTIVE",
        dueDate:    body.dueDate ? new Date(body.dueDate) : null,
      },
      include: { book: true, giver: true, receiver: true },
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

  // POST /api/loans/borrow — demander un emprunt (PENDING + notif au propriétaire)
  .post("/borrow", async ({ userId, body, set }) => {
    const book = await prisma.book.findFirst({
      where: { id: body.bookId, userId: body.giverId },
    });
    if (!book) { set.status = 404; throw new Error("Livre introuvable"); }

    const loan = await prisma.loan.create({
      data: {
        bookId:     body.bookId,
        giverId:    body.giverId,
        receiverId: userId,
        direction:  "OUT",
        status:     "PENDING",
      },
      include: { book: true, giver: true, receiver: true },
    });

    // Notifier le propriétaire du livre
    await prisma.appNotification.create({
      data: {
        type:       "LOAN_REQUEST",
        userId:     body.giverId,
        fromUserId: userId,
        loanId:     loan.id,
        bookTitle:  book.title,
      },
    });

    return {
      id:        loan.id,
      status:    "pending",
      direction: "in",
      since:     loan.since.toISOString(),
      book:      serializeBook(loan.book),
      partner:   serializeUser(loan.giver),
    };
  }, {
    body: t.Object({
      bookId:  t.String(),
      giverId: t.String(),
    }),
  })

  // PATCH /api/loans/:id/accept — le propriétaire accepte le prêt
  .patch("/:id/accept", async ({ userId, params, body, set }) => {
    const loan = await prisma.loan.findFirst({
      where: { id: params.id, giverId: userId, status: "PENDING" },
      include: { book: true },
    });
    if (!loan) { set.status = 404; throw new Error("Demande introuvable"); }

    const dueDate = body.dueDays ? new Date(Date.now() + body.dueDays * 86400000) : null;

    await prisma.loan.update({
      where: { id: params.id },
      data: { status: "ACTIVE", dueDate },
    });

    // Notifier l'emprunteur
    await prisma.appNotification.create({
      data: {
        type:       "LOAN_ACCEPTED",
        userId:     loan.receiverId,
        fromUserId: userId,
        loanId:     loan.id,
        bookTitle:  loan.book.title,
      },
    });

    // Supprimer la notif LOAN_REQUEST (elle a été traitée)
    await prisma.appNotification.deleteMany({
      where: { loanId: params.id, type: "LOAN_REQUEST", userId },
    });

    return { accepted: true };
  }, {
    body: t.Object({ dueDays: t.Optional(t.Number()) }),
  })

  // PATCH /api/loans/:id/decline
  .patch("/:id/decline", async ({ userId, params, set }) => {
    const loan = await prisma.loan.findFirst({
      where: { id: params.id, giverId: userId, status: "PENDING" },
      include: { book: true },
    });
    if (!loan) { set.status = 404; throw new Error("Demande introuvable"); }

    await prisma.loan.update({
      where: { id: params.id },
      data: { status: "DECLINED" },
    });

    await prisma.appNotification.create({
      data: {
        type:       "LOAN_DECLINED",
        userId:     loan.receiverId,
        fromUserId: userId,
        loanId:     loan.id,
        bookTitle:  loan.book.title,
      },
    });

    await prisma.appNotification.deleteMany({
      where: { loanId: params.id, type: "LOAN_REQUEST", userId },
    });

    return { declined: true };
  })

  // POST /api/loans/:id/remind — le prêteur relance l'emprunteur
  .post("/:id/remind", async ({ userId, params, set }) => {
    const loan = await prisma.loan.findFirst({
      where: { id: params.id, giverId: userId, status: "ACTIVE" },
      include: { book: true },
    });
    if (!loan) { set.status = 404; throw new Error("Prêt introuvable"); }

    await prisma.appNotification.create({
      data: {
        type:       "LOAN_REMINDER",
        userId:     loan.receiverId,
        fromUserId: userId,
        loanId:     loan.id,
        bookTitle:  loan.book.title,
      },
    });

    return { reminded: true };
  })

  // PATCH /api/loans/:id/return
  .patch("/:id/return", async ({ userId, params, set }) => {
    const loan = await prisma.loan.findFirst({
      where: { id: params.id, OR: [{ giverId: userId }, { receiverId: userId }] },
      include: { book: true },
    });
    if (!loan) { set.status = 404; throw new Error("Prêt introuvable"); }

    await prisma.loan.update({
      where: { id: params.id },
      data: { returned: true, returnedAt: new Date() },
    });

    // Notifier le prêteur que le livre est rendu
    await prisma.appNotification.create({
      data: {
        type:       "LOAN_RETURNED",
        userId:     loan.giverId,
        fromUserId: userId,
        loanId:     loan.id,
        bookTitle:  loan.book.title,
      },
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
