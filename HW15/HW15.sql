-- Создание БД
IF DB_ID (N'TOWN_LIBRARY') IS NOT NULL 
	DROP DATABASE TOWN_LIBRARY; 
GO 
CREATE  DATABASE TOWN_LIBRARY;
GO
USE TOWN_LIBRARY;
GO

-- ========================= СОЗДАНИЕ СПРАВОЧНИКОВ  =====================================
-- ************************************** [Genres]
drop table if exists [Genres]
go

CREATE TABLE [Genres]
(
 [GenreID] bigint IDENTITY (1, 1) NOT NULL ,
 [Name]    varchar(50) NOT NULL ,

 CONSTRAINT [PK_Genres] PRIMARY KEY CLUSTERED ([GenreID] ASC)
);
GO
-- ************************************** [Authors]
drop table if exists [Authors]
go
CREATE TABLE [Authors]
(
 [AuthorID]    bigint IDENTITY (1, 1) NOT NULL ,
 [Born]        datetime2 NOT NULL ,
 [Dead]        datetime2 NULL ,
 [Description] nvarchar(max) SPARSE NULL ,
 [WikiURL]     varchar(200) NOT NULL ,


 CONSTRAINT [PK_Authors] PRIMARY KEY CLUSTERED ([AuthorID] ASC)
);
GO

-- ************************************** [Books]
drop table if exists [Books]
go

CREATE TABLE [Books]
(
 [BookID]       bigint identity(1,1) NOT NULL ,
 [GenreID]      bigint NOT NULL ,
 [AuthorID]     bigint NOT NULL ,
 [Name]         varchar(255) NOT NULL ,
 [Description]  varchar(max) NOT NULL ,
 [Year]         int NOT NULL ,
 [ISBN]         varchar(20) NOT NULL ,
 [Izdatelstvo]  varchar(50) NOT NULL ,
 [BarCode_GUID] varchar(50) NOT NULL ,

 CONSTRAINT [PK_Books] PRIMARY KEY CLUSTERED ([BookID] ASC),
 CONSTRAINT [FK_Book_Author] FOREIGN KEY ([AuthorID])  REFERENCES [Authors]([AuthorID]),
 CONSTRAINT [FK_Book_Genre_Genre] FOREIGN KEY ([GenreID])  REFERENCES [Genres]([GenreID])
);
GO


CREATE NONCLUSTERED INDEX [IX_Books_Genres] ON [Books] ( [GenreID] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_Books_Authors] ON [Books] ([AuthorID] ASC)
GO

-- ************************************** [Cupboards]
drop table if exists [Cupboards]
go
CREATE TABLE [Cupboards]
(
 [CupboardID] bigint IDENTITY (1, 1) NOT NULL ,
 [Locate]     varchar(200) NOT NULL ,

 CONSTRAINT [PK_Cupboards] PRIMARY KEY CLUSTERED ([CupboardID] ASC)
);
GO
-- ************************************** [Users]
drop table if exists [Users]
go
CREATE TABLE [Users]
(
 [UserID]       bigint IDENTITY (1, 1) NOT NULL ,
 [Name]         varchar(200) NOT NULL ,

 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([UserID] ASC),

);
GO

-- ************************************** [Readers]
drop table if exists [Readers]
go
CREATE TABLE [Readers]
(
 [ReaderID]            bigint IDENTITY (1, 1) NOT NULL ,
 [FIO]                 varchar(200) NOT NULL ,
 [BORN]                datetime2 not null,
 [Address]             varchar(200) NOT NULL ,
 [Phone]               varchar(20) NOT NULL ,
 [ReaderTicketBarcode] varchar(50) NOT NULL ,


 CONSTRAINT [PK_Readers] PRIMARY KEY CLUSTERED ([ReaderID] ASC)
);
GO
-- Читателем библиотеки может быть человек старше 18 лет.
ALTER TABLE [Readers] 
	ADD CONSTRAINT Readers_BORN 
		CHECK (datediff(yy, BORN, getdate()) >=18);
go
----- ======================= Учет движения книг  ========================---
-- ************************************** [Docs]
drop table if exists [Docs]
go

CREATE TABLE [Docs]
(
 [DocID]        bigint IDENTITY (1, 1) NOT NULL ,
 [CreateUserID] bigint NOT NULL ,
 [CreateDate]   datetime2 NOT NULL ,
 [UpdateUserID] bigint NOT NULL ,
 [UpdateDate]   datetime2 NOT NULL ,
 
 CONSTRAINT [PK_Docs] PRIMARY KEY CLUSTERED ([DocID] ASC),
 CONSTRAINT [FK_Docs_UsersCreate] FOREIGN KEY ([CreateUserID])  REFERENCES [Users]([UserID]),
 CONSTRAINT [FK_Docs_UsersUpdate] FOREIGN KEY ([UpdateUserID])  REFERENCES [Users]([UserID]),

);
GO

-- ************************************** [DocsIn]
drop table if exists [DocsIn]
go

CREATE TABLE [DocsIn]
(
 [DocInID]    bigint IDENTITY (1, 1) NOT NULL ,
 [DocID]      bigint NOT NULL ,
 [CupboardID] bigint NOT NULL ,
 [BookID]     bigint NOT NULL ,

 CONSTRAINT [PK_DocsIn] PRIMARY KEY CLUSTERED ([DocInID] ASC),
 CONSTRAINT [FK_DocsIn_Cupboards] FOREIGN KEY ([CupboardID])  REFERENCES [Cupboards]([CupboardID]),
 CONSTRAINT [FK_DocsIn_Books] FOREIGN KEY ([BookID])  REFERENCES [Books]([BookID]),
 CONSTRAINT [FK_DocsIn_Docs] FOREIGN KEY ([DocID])  REFERENCES [Docs]([DocID]),
);
GO

CREATE NONCLUSTERED INDEX [IX_DOCSIn_Cupboard] ON [DocsIn] ([CupboardID] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_DOCSIn_Book] ON [DocsIn] ([BookID] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_DOCSIn_Docs] ON [DocsIn] ([DocID] ASC)
GO

-- ************************************** [DocsInOut]
drop table if exists DocsInOut
go

CREATE TABLE [DocsInOut]
(
 [DocInOutID]    bigint IDENTITY (1, 1) NOT NULL ,
 [DocID]         bigint NOT NULL ,
 [BookID]        bigint NOT NULL ,
 [CupboardInID]  bigint NOT NULL ,
 [CupboardOutId] bigint NOT NULL ,


 CONSTRAINT [PK_DocsInOut] PRIMARY KEY CLUSTERED ([DocInOutID] ASC),
 CONSTRAINT [FK_DocsInOut_CupboardIn] FOREIGN KEY ([CupboardInID])  REFERENCES [Cupboards]([CupboardID]),
 CONSTRAINT [FK_DocsInOut_CupboardOut] FOREIGN KEY ([CupboardOutID])  REFERENCES [Cupboards]([CupboardID]),
 CONSTRAINT [FK_DocsInOut_Books] FOREIGN KEY ([BookID])  REFERENCES [Books]([BookID]),
 CONSTRAINT [FK_DocsInOut_Docs] FOREIGN KEY ([DocID])  REFERENCES [Docs]([DocID]),
);
GO
CREATE NONCLUSTERED INDEX [IX_DOCSInOut_CupboardIn] ON [DocsInOut] ([CupboardInID] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_DOCSInOut_CupboardOut] ON [DocsInOut] ([CupboardOutID] ASC)
GO


CREATE NONCLUSTERED INDEX [IX_DOCSInOut_Book] ON [DocsInOut] ([BookID] ASC)
GO

-- ************************************** [DocsOut]
drop table if exists DocsOut
go
CREATE TABLE [DocsOut]
(
 [DocOutID]   bigint IDENTITY (1, 1) NOT NULL ,
 [DocID]      bigint NOT NULL ,
 [BookID]     bigint NOT NULL ,
 [ReaderID]   bigint NOT NULL ,
 [DateReturn] datetime2 NOT NULL ,


 CONSTRAINT [PK_DocsOut] PRIMARY KEY CLUSTERED ([DocOutID] ASC),
 CONSTRAINT [FK_DocsOut_Books] FOREIGN KEY ([BookID])  REFERENCES [Books]([BookID]),
 CONSTRAINT [FK_DocsOut_Docs] FOREIGN KEY ([DocID])  REFERENCES [Docs]([DocID]),
);
GO
CREATE NONCLUSTERED INDEX [IX_DOCSOut_Book] ON [DocsOut] ([BookID] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_DOCSOut_Docs] ON [DocsOut] ([DocID] ASC)
GO
