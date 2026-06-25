BEGIN;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM "WorkflowInbox"
        GROUP BY "ProcessId", "IdentityId"
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'BREAKING CHANGES DETECTED: Duplicate ProcessId and IdentityId values found in WorkflowInbox table. Please contact support support@optimajet.com.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM "WorkflowProcessInstancePersistence"
        GROUP BY "ProcessId", "ParameterName"
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'BREAKING CHANGES DETECTED: Duplicate ProcessId and ParameterName values found in WorkflowProcessInstancePersistence table. Please contact support support@optimajet.com.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM "WorkflowProcessTimer"
        GROUP BY "ProcessId", "Name"
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'BREAKING CHANGES DETECTED: Duplicate ProcessId and Name values found in WorkflowProcessTimer table. Please contact support support@optimajet.com.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM "WorkflowGlobalParameter"
        GROUP BY "Type", "Name"
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'BREAKING CHANGES DETECTED: Duplicate Type and Name values found in WorkflowGlobalParameter table. Please contact support support@optimajet.com.';
    END IF;
END $$;

ALTER TABLE "WorkflowProcessInstance"
    ADD COLUMN IF NOT EXISTS "CalendarName" character varying(256) NULL;

CREATE INDEX IF NOT EXISTS "IX_CalendarName"
    ON "WorkflowProcessInstance" USING btree ("CalendarName");

CREATE UNIQUE INDEX IF NOT EXISTS "WorkflowInbox_ProcessId_IdentityId_idx"
    ON "WorkflowInbox" USING btree ("ProcessId", "IdentityId");

CREATE UNIQUE INDEX IF NOT EXISTS "WorkflowProcessInstancePersistence_ProcessId_ParameterName_idx"
    ON "WorkflowProcessInstancePersistence" USING btree ("ProcessId", "ParameterName");

CREATE UNIQUE INDEX IF NOT EXISTS "WorkflowProcessTimer_ProcessId_Name_idx"
    ON "WorkflowProcessTimer" USING btree ("ProcessId", "Name");

CREATE UNIQUE INDEX IF NOT EXISTS "WorkflowGlobalParameter_Type_Name_idx"
    ON "WorkflowGlobalParameter" USING btree ("Type", "Name");

CREATE TABLE IF NOT EXISTS "WorkflowForm" (
    "Id" uuid NOT NULL,
    "Name" character varying(512) NOT NULL,
    "Version" integer NOT NULL,
    "CreationDate" timestamp NOT NULL DEFAULT localtimestamp,
    "UpdatedDate" timestamp NOT NULL DEFAULT localtimestamp,
    "Definition" text NOT NULL,
    "Lock" integer NOT NULL,
    CONSTRAINT "WorkflowForm_pkey" PRIMARY KEY ("Id"),
    CONSTRAINT "WorkflowForm_Name_Version_key" UNIQUE ("Name", "Version")
);

DROP INDEX IF EXISTS "WorkflowProcessScheme_DefiningParametersHash_idx";

ALTER TABLE "WorkflowProcessScheme"
    ALTER COLUMN "DefiningParametersHash" DROP NOT NULL;

ALTER TABLE "WorkflowProcessScheme"
    ALTER COLUMN "DefiningParameters" DROP NOT NULL;

ALTER TABLE "WorkflowProcessInstance"
    ALTER COLUMN "IsDeterminingParametersChanged" DROP NOT NULL;

COMMIT;
