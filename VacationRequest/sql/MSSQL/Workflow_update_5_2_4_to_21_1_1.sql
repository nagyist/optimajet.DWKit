SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS (
        SELECT 1
        FROM [dbo].[WorkflowProcessInstancePersistence]
        WHERE LEN([ParameterName]) > 900
    )
    BEGIN
        RAISERROR ('BREAKING CHANGES DETECTED: Some rows in the ParameterName column in WorkflowProcessInstancePersistence table are too long. Please contact support support@optimajet.com.', 16, 1);
    END;

    IF EXISTS (
        SELECT 1
        FROM [dbo].[WorkflowProcessTimer]
        WHERE LEN([Name]) > 900
    )
    BEGIN
        RAISERROR ('BREAKING CHANGES DETECTED: Some rows in the Name column in WorkflowProcessTimer table are too long. Please contact support support@optimajet.com.', 16, 1);
    END;

    IF EXISTS (
        SELECT 1
        FROM [dbo].[WorkflowProcessInstancePersistence]
        GROUP BY [ProcessId], [ParameterName]
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR ('BREAKING CHANGES DETECTED: Duplicate ProcessId and ParameterName values found in WorkflowProcessInstancePersistence table. Please contact support support@optimajet.com.', 16, 1);
    END;

    IF EXISTS (
        SELECT 1
        FROM [dbo].[WorkflowInbox]
        GROUP BY [ProcessId], [IdentityId]
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR ('BREAKING CHANGES DETECTED: Duplicate ProcessId and IdentityId values found in WorkflowInbox table. Please contact support support@optimajet.com.', 16, 1);
    END;

    IF EXISTS (
        SELECT 1
        FROM [dbo].[WorkflowProcessTimer]
        GROUP BY [ProcessId], [Name]
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR ('BREAKING CHANGES DETECTED: Duplicate ProcessId and Name values found in WorkflowProcessTimer table. Please contact support support@optimajet.com.', 16, 1);
    END;

    IF COL_LENGTH('dbo.WorkflowProcessInstance', 'CalendarName') IS NULL
    BEGIN
        ALTER TABLE [dbo].[WorkflowProcessInstance]
        ADD [CalendarName] NVARCHAR(450) NULL;

        PRINT 'WorkflowProcessInstance.CalendarName added';
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM [sys].[indexes]
        WHERE [name] = 'IX_CalendarName'
            AND [object_id] = OBJECT_ID('dbo.WorkflowProcessInstance')
    )
    BEGIN
        CREATE INDEX [IX_CalendarName]
            ON [dbo].[WorkflowProcessInstance] ([CalendarName]);

        PRINT 'IX_CalendarName created';
    END;

    IF EXISTS (
        SELECT 1
        FROM [sys].[columns]
        WHERE [object_id] = OBJECT_ID('dbo.WorkflowProcessInstancePersistence')
            AND [name] = 'ParameterName'
            AND ([max_length] <> 1800 OR [is_nullable] = 1)
    )
    BEGIN
        ALTER TABLE [dbo].[WorkflowProcessInstancePersistence]
        ALTER COLUMN [ParameterName] NVARCHAR(900) NOT NULL;

        PRINT 'WorkflowProcessInstancePersistence.ParameterName altered';
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM [sys].[indexes]
        WHERE [name] = 'IX_ProcessId_ParameterName'
            AND [object_id] = OBJECT_ID('dbo.WorkflowProcessInstancePersistence')
    )
    BEGIN
        CREATE UNIQUE INDEX [IX_ProcessId_ParameterName]
            ON [dbo].[WorkflowProcessInstancePersistence] ([ProcessId], [ParameterName]);

        PRINT 'IX_ProcessId_ParameterName created';
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM [sys].[indexes]
        WHERE [name] = 'IX_ProcessId_IdentityId'
            AND [object_id] = OBJECT_ID('dbo.WorkflowInbox')
    )
    BEGIN
        CREATE UNIQUE INDEX [IX_ProcessId_IdentityId]
            ON [dbo].[WorkflowInbox] ([ProcessId], [IdentityId]);

        PRINT 'IX_ProcessId_IdentityId created';
    END;

    IF EXISTS (
        SELECT 1
        FROM [sys].[columns]
        WHERE [object_id] = OBJECT_ID('dbo.WorkflowProcessTimer')
            AND [name] = 'Name'
            AND ([max_length] <> 1800 OR [is_nullable] = 1)
    )
    BEGIN
        ALTER TABLE [dbo].[WorkflowProcessTimer]
        ALTER COLUMN [Name] NVARCHAR(900) NOT NULL;

        PRINT 'WorkflowProcessTimer.Name altered';
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM [sys].[indexes]
        WHERE [name] = 'IX_ProcessId_Name'
            AND [object_id] = OBJECT_ID('dbo.WorkflowProcessTimer')
    )
    BEGIN
        CREATE UNIQUE INDEX [IX_ProcessId_Name]
            ON [dbo].[WorkflowProcessTimer] ([ProcessId], [Name]);

        PRINT 'IX_ProcessId_Name created';
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_SCHEMA] = 'dbo'
            AND [TABLE_NAME] = N'WorkflowForm'
    )
    BEGIN
        CREATE TABLE [dbo].[WorkflowForm] (
            [Id] UNIQUEIDENTIFIER NOT NULL,
            [Name] NVARCHAR(512) NOT NULL,
            [Version] INT NOT NULL,
            [CreationDate] DATETIME NOT NULL DEFAULT GETDATE(),
            [UpdatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
            [Definition] NVARCHAR(MAX) NOT NULL,
            [Lock] INT NOT NULL,
            CONSTRAINT [PK_WorkflowForm] PRIMARY KEY ([Id]),
            CONSTRAINT [UQ_WorkflowForm_Name_Version] UNIQUE ([Name], [Version])
        );

        PRINT 'WorkflowForm created';
    END;

    IF EXISTS (
        SELECT 1
        FROM [sys].[indexes]
        WHERE [name] = 'IX_SchemeCode_Hash_IsObsolete'
            AND [object_id] = OBJECT_ID('dbo.WorkflowProcessScheme')
    )
    BEGIN
        DROP INDEX [IX_SchemeCode_Hash_IsObsolete] ON [dbo].[WorkflowProcessScheme];

        PRINT 'IX_SchemeCode_Hash_IsObsolete dropped';
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM [sys].[indexes]
        WHERE [name] = 'IX_SchemeCode_IsObsolete'
            AND [object_id] = OBJECT_ID('dbo.WorkflowProcessScheme')
    )
    BEGIN
        CREATE INDEX [IX_SchemeCode_IsObsolete]
            ON [dbo].[WorkflowProcessScheme] ([SchemeCode], [IsObsolete]);

        PRINT 'IX_SchemeCode_IsObsolete created';
    END;

    IF EXISTS (
        SELECT 1
        FROM [sys].[columns]
        WHERE [object_id] = OBJECT_ID('dbo.WorkflowProcessScheme')
            AND [name] = 'DefiningParametersHash'
            AND [is_nullable] = 0
    )
    BEGIN
        ALTER TABLE [dbo].[WorkflowProcessScheme]
        ALTER COLUMN [DefiningParametersHash] NVARCHAR(24) NULL;

        PRINT 'WorkflowProcessScheme.DefiningParametersHash altered';
    END;

    IF EXISTS (
        SELECT 1
        FROM [sys].[columns]
        WHERE [object_id] = OBJECT_ID('dbo.WorkflowProcessScheme')
            AND [name] = 'DefiningParameters'
            AND [is_nullable] = 0
    )
    BEGIN
        ALTER TABLE [dbo].[WorkflowProcessScheme]
        ALTER COLUMN [DefiningParameters] NTEXT NULL;

        PRINT 'WorkflowProcessScheme.DefiningParameters altered';
    END;

    DECLARE @ConstraintName NVARCHAR(200);
    DECLARE @DropConstraintSql NVARCHAR(MAX);

    SELECT @ConstraintName = dc.[name]
    FROM [sys].[default_constraints] dc
    INNER JOIN [sys].[columns] c
        ON dc.[parent_object_id] = c.[object_id]
        AND dc.[parent_column_id] = c.[column_id]
    WHERE dc.[parent_object_id] = OBJECT_ID('dbo.WorkflowProcessInstance')
        AND c.[name] = 'IsDeterminingParametersChanged';

    IF @ConstraintName IS NOT NULL
    BEGIN
        SET @DropConstraintSql = N'ALTER TABLE [dbo].[WorkflowProcessInstance] DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @DropConstraintSql;

        PRINT 'WorkflowProcessInstance.IsDeterminingParametersChanged default constraint dropped';
    END;

    IF EXISTS (
        SELECT 1
        FROM [sys].[columns]
        WHERE [object_id] = OBJECT_ID('dbo.WorkflowProcessInstance')
            AND [name] = 'IsDeterminingParametersChanged'
            AND [is_nullable] = 0
    )
    BEGIN
        ALTER TABLE [dbo].[WorkflowProcessInstance]
        ALTER COLUMN [IsDeterminingParametersChanged] BIT NULL;

        PRINT 'WorkflowProcessInstance.IsDeterminingParametersChanged altered';
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
