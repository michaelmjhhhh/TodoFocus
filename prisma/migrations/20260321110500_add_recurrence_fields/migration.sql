-- AlterTable
ALTER TABLE "Todo" ADD COLUMN "recurrence" TEXT;

-- AlterTable
ALTER TABLE "Todo" ADD COLUMN "recurrenceInterval" INTEGER NOT NULL DEFAULT 1;

-- AlterTable
ALTER TABLE "Todo" ADD COLUMN "lastCompletedAt" DATETIME;
