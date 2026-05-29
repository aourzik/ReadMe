import { Elysia, t } from "elysia";
import { authMiddleware } from "../middleware/auth";
import { prisma } from "../utils/prisma";

export const bookRoutes = new Elysia({ prefix: "/books" })
  .use(authMiddleware())

  // GET /api/books
  .get("/", async ({ userId, query }) => {
    const where: any = { userId };
    if (query.status) where.status = query.status.toUpperCase();

    const books = await prisma.book.findMany({
      where,
      include: {
        loans: {
          where: { status: "ACTIVE", returned: false },
          include: { receiver: true },
          take: 1,
        },
      },
      orderBy: { addedAt: "desc" },
    });
    return books.map(serializeBook);
  }, {
    query: t.Object({ status: t.Optional(t.String()) }),
  })

  // GET /api/books/:id
  .get("/:id", async ({ userId, params, set }) => {
    const book = await prisma.book.findFirst({
      where: { id: params.id, userId },
      include: {
        loans: {
          where: { status: "ACTIVE", returned: false },
          include: { receiver: true },
          take: 1,
        },
      },
    });
    if (!book) { set.status = 404; throw new Error("Livre introuvable"); }
    return serializeBook(book);
  })

  // POST /api/books
  .post("/", async ({ userId, body }) => {
    const book = await prisma.book.create({
      data: {
        ...body,
        status: (body.status?.toUpperCase() as any) || "WISHLIST",
        userId,
      },
    });
    await prisma.activity.create({ data: { type: "BOOK_ADDED", userId, bookId: book.id } });
    return serializeBook(book);
  }, {
    body: t.Object({
      title:        t.String(),
      author:       t.String(),
      year:         t.Number(),
      pages:        t.Optional(t.Number()),
      description:  t.Optional(t.String()),
      coverUrl:     t.Optional(t.String()),
      googleBooksId:t.Optional(t.String()),
      tags:         t.Optional(t.Array(t.String())),
      status:       t.Optional(t.String()),
    }),
  })

  // PATCH /api/books/:id
  .patch("/:id", async ({ userId, params, body, set }) => {
    const existing = await prisma.book.findFirst({ where: { id: params.id, userId } });
    if (!existing) { set.status = 404; throw new Error("Livre introuvable"); }

    const data: any = { ...body };
    const statusUpper = body.status?.toUpperCase();
    if (statusUpper) data.status = statusUpper;
    if (statusUpper === "READ" && !existing.finishedAt) {
      data.finishedAt = new Date();
    }
    if (statusUpper === "READING" && !existing.startedAt) {
      data.startedAt = new Date();
    }

    const book = await prisma.book.update({ where: { id: params.id }, data });

    // Activités automatiques
    if (statusUpper === "READ" && !existing.finishedAt) {
      await prisma.activity.create({ data: { type: "BOOK_FINISHED", userId, bookId: book.id } });
    } else if (body.rating != null && body.rating > 0 && existing.rating === 0) {
      await prisma.activity.create({ data: { type: "BOOK_RATED", userId, bookId: book.id } });
    }

    return serializeBook(book);
  }, {
    body: t.Object({
      title:       t.Optional(t.String()),
      author:      t.Optional(t.String()),
      year:        t.Optional(t.Number()),
      pages:       t.Optional(t.Number()),
      rating:      t.Optional(t.Number()),
      description: t.Optional(t.String()),
      coverUrl:    t.Optional(t.String()),
      tags:        t.Optional(t.Array(t.String())),
      status:      t.Optional(t.String()),
      isFavorite:  t.Optional(t.Boolean()),
    }),
  })

  // DELETE /api/books/:id
  .delete("/:id", async ({ userId, params, set }) => {
    const existing = await prisma.book.findFirst({ where: { id: params.id, userId } });
    if (!existing) { set.status = 404; throw new Error("Livre introuvable"); }
    await prisma.book.delete({ where: { id: params.id } });
    return { deleted: true };
  });

function serializeBook(book: any) {
  const activeLoan = book.loans?.[0];
  return {
    id:            book.id,
    title:         book.title,
    author:        book.author,
    year:          book.year,
    pages:         book.pages,
    rating:        book.rating,
    description:   book.description,
    coverUrl:      book.coverUrl,
    googleBooksId: book.googleBooksId,
    tags:          book.tags,
    status:        book.status.toLowerCase(),
    isFavorite:    book.isFavorite,
    addedAt:       book.addedAt?.toISOString(),
    startedAt:     book.startedAt?.toISOString(),
    finishedAt:    book.finishedAt?.toISOString(),
    userId:        book.userId,
    lentTo:        activeLoan?.receiver?.name ?? null,
    lentToUserId:  activeLoan?.receiverId ?? null,
    lentSince:     activeLoan?.since?.toISOString() ?? null,
    lentUntil:     activeLoan?.dueDate?.toISOString() ?? null,
  };
}
