-- ************************************** [Authors]
CREATE TABLE [Authors]
(
 [AuthorID]    bigint IDENTITY (1, 1) NOT NULL ,
 [Born]        datetime2 NOT NULL ,
 [Dead]        datetime2 NULL ,
 [Description] nvarchar(255) SPARSE NULL ,
 [WikiURL]     varchar(200) NOT NULL ,


 CONSTRAINT [PK_8] PRIMARY KEY CLUSTERED ([AuthorID] ASC)
);
GO

-- ************************************** [Books]
CREATE TABLE [Books]
(
 [GenreID]      bigint NOT NULL ,
 [AuthorID]     bigint NOT NULL ,
 [Name]         varchar(50) NOT NULL ,
 [Description]  varchar(255) NOT NULL ,
 [Year]         int NOT NULL ,
 [Izdatelstvo]  varchar(50) NOT NULL ,
 [BarCode_GUID] varchar(50) NOT NULL ,
 [BookID]        NOT NULL ,


 CONSTRAINT [PK_5] PRIMARY KEY CLUSTERED ([BookID] ASC),
 CONSTRAINT [FK_Book_Author] FOREIGN KEY ([AuthorID])  REFERENCES [Authors]([AuthorID]),
 CONSTRAINT [FK_Book_Genre_Genre] FOREIGN KEY ([GenreID])  REFERENCES [Genres]([GenreID])
);
GO


CREATE NONCLUSTERED INDEX [fkIdx_21] ON [Books] 
 (
  [GenreID] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_25] ON [Books] 
 (
  [AuthorID] ASC
 )

GO

-- ************************************** [Cupboards]
CREATE TABLE [Cupboards]
(
 [Locate]     varchar(200) NOT NULL ,
 [CupboardID] bigint IDENTITY (1, 1) NOT NULL ,


 CONSTRAINT [PK_63] PRIMARY KEY CLUSTERED ([CupboardID] ASC)
);
GO
-- ************************************** [Users]
CREATE TABLE [Users]
(
 [Name]         varchar(200) NOT NULL ,
 [UpdateUserID] bigint NOT NULL ,
 [UserID]       bigint IDENTITY (1, 1) NOT NULL ,


 CONSTRAINT [PK_100] PRIMARY KEY CLUSTERED ([UserID] ASC),
 CONSTRAINT [FK_56] FOREIGN KEY ([UpdateUserID])  REFERENCES [Docs]([DocID])
);
GO


CREATE NONCLUSTERED INDEX [fkIdx_58] ON [Users] 
 (
  [UpdateUserID] ASC
 )
go
-- ************************************** [Genres]
CREATE TABLE [Genres]
(
 [GenreID] bigint IDENTITY (1, 1) NOT NULL ,
 [Name]    varchar(50) NOT NULL ,


 CONSTRAINT [PK_16] PRIMARY KEY CLUSTERED ([GenreID] ASC)
);
GO
-- ************************************** [Readers]
CREATE TABLE [Readers]
(
 [FIO]                 varchar(200) NOT NULL ,
 [Address]             varchar(200) NOT NULL ,
 [Phone]               varchar(20) NOT NULL ,
 [ReaderTicketBarcode] varchar(50) NOT NULL ,
 [ReaderID]            bigint IDENTITY (1, 1) NOT NULL ,


 CONSTRAINT [PK_33] PRIMARY KEY CLUSTERED ([ReaderID] ASC)
);
GO
-- ************************************** [Docs]
CREATE TABLE [Docs]
(
 [CreateUserID] bigint NOT NULL ,
 [CreateDate]   datetime2 NOT NULL ,
 [UpdateUserID] bigint NOT NULL ,
 [UpdateDate]   datetime2 NOT NULL ,
 [DocInID]      bigint NOT NULL ,
 [DocID]        bigint IDENTITY (1, 1) NOT NULL ,


 CONSTRAINT [PK_81] PRIMARY KEY CLUSTERED ([DocID] ASC),
 CONSTRAINT [FK_53] FOREIGN KEY ([CreateUserID])  REFERENCES [Users]([UserID]),
 CONSTRAINT [FK_97] FOREIGN KEY ([DocInID])  REFERENCES [DocsIn]([DocInID])
);
GO


CREATE NONCLUSTERED INDEX [fkIdx_55] ON [Docs] 
 (
  [CreateUserID] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_99] ON [Docs] 
 (
  [DocInID] ASC
 )

GO
-- ************************************** [DocsIn]
CREATE TABLE [DocsIn]
(
 [DocID]      bigint NOT NULL ,
 [CupboardID] bigint NOT NULL ,
 [BookID]      NOT NULL ,
 [DocInID]    bigint IDENTITY (1, 1) NOT NULL ,


 CONSTRAINT [PK_67] PRIMARY KEY CLUSTERED ([DocInID] ASC),
 CONSTRAINT [FK_91] FOREIGN KEY ([CupboardID])  REFERENCES [Cupboards]([CupboardID]),
 CONSTRAINT [FK_94] FOREIGN KEY ([BookID])  REFERENCES [Books]([BookID])
);
GO


CREATE NONCLUSTERED INDEX [fkIdx_93] ON [DocsIn] 
 (
  [CupboardID] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_96] ON [DocsIn] 
 (
  [BookID] ASC
 )

GO
-- ************************************** [DocsInOut]
CREATE TABLE [DocsInOut]
(
 [DocInOutID]    bigint IDENTITY (1, 1) NOT NULL ,
 [DocID]         bigint NOT NULL ,
 [BookID]        bigint NOT NULL ,
 [CupboardInID]  bigint NOT NULL ,
 [CupboardOutId] bigint NOT NULL ,


 CONSTRAINT [PK_110] PRIMARY KEY CLUSTERED ([DocInOutID] ASC)
);
GO
-- ************************************** [DocsOut]
CREATE TABLE [DocsOut]
(
 [DocOutID]   bigint IDENTITY (1, 1) NOT NULL ,
 [DocID]      bigint NOT NULL ,
 [BookID]     bigint NOT NULL ,
 [ReaderID]   bigint NOT NULL ,
 [DateReturn] datetime2 NOT NULL ,


 CONSTRAINT [PK_103] PRIMARY KEY CLUSTERED ([DocOutID] ASC)
);
GO
