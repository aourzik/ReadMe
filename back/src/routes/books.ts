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
    if (body.status) data.status = body.status.toUpperCase();
    if (body.status === "READ" && !existing.finishedAt) {
      data.finishedAt = new Date();
      // Increment booksReadThisYear if same year
      const now = new Date();
      if (now.getFullYear() === new Date().getFullYear()) {
        await prisma.user.update({
          where: { id: userId },
          data: { booksReadThisYear: { increment: 1 } },
        });
      }
    }
    if (body.status === "READING" && !existing.startedAt) {
      data.startedAt = new Date();
    }

    const book = await prisma.book.update({ where: { id: params.id }, data });
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
    addedAt:       book.addedAt?.toISOString(),
    startedAt:     book.startedAt?.toISOString(),
    finishedAt:    book.finishedAt?.toISOString(),
    userId:        book.userId,
  };
}
