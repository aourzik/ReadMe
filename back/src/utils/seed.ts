import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Seeding database...");

  const hash = await bcrypt.hash("password123", 12);

  const alice = await prisma.user.upsert({
    where: { email: "alice@readme.app" },
    update: {},
    create: {
      name: "Alice Mercier",
      email: "alice@readme.app",
      passwordHash: hash,
      handle: "alice.lit",
      location: "Paris",
      readingGoal: 24,
      booksReadThisYear: 5,
    },
  });

  const bob = await prisma.user.upsert({
    where: { email: "bob@readme.app" },
    update: {},
    create: {
      name: "Bob Dubois",
      email: "bob@readme.app",
      passwordHash: hash,
      handle: "bob.reads",
    },
  });

  // Books for Alice
  await prisma.book.createMany({
    skipDuplicates: true,
    data: [
      {
        title: "La Maison du Verger",
        author: "Élise Lavandier",
        year: 2023,
        pages: 412,
        rating: 4.8,
        tags: ["Roman", "Famille"],
        description: "Trois sœurs reviennent dans la maison de leur enfance.",
        status: "READ",
        userId: alice.id,
      },
      {
        title: "Les Chemins de Soie",
        author: "Hiroshi Tanaka",
        year: 2021,
        pages: 298,
        rating: 4.5,
        tags: ["Voyage", "Essai"],
        description: "Un journal méditatif sur les routes oubliées du Japon.",
        status: "READING",
        userId: alice.id,
      },
      {
        title: "Nuit Claire",
        author: "Anouk Béranger",
        year: 2024,
        pages: 184,
        rating: 4.2,
        tags: ["Poésie"],
        description: "Soixante poèmes courts sur l'insomnie.",
        status: "READ",
        userId: alice.id,
      },
    ],
  });

  // Friendship
  await prisma.friendship.upsert({
    where: { userAId_userBId: { userAId: alice.id, userBId: bob.id } },
    update: {},
    create: { userAId: alice.id, userBId: bob.id },
  });

  console.log("✅ Seed done!");
  console.log("  alice@readme.app / password123");
  console.log("  bob@readme.app   / password123");
}

main().catch(console.error).finally(() => prisma.$disconnect());
