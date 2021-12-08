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
 [FIO]         varchar(255),
 [DateBorn]        datetime2 NOT NULL ,
 [DateEnd]        datetime2 NULL ,
 [Description] nvarchar(max) SPARSE NULL ,
 [WikiURL]     varchar(200) NOT NULL ,


 CONSTRAINT [PK_Authors] PRIMARY KEY CLUSTERED ([AuthorID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Authors_Genres] ON [Authors] ( FIO ASC)
GO

-- ************************************** [Books]
drop table if exists [Books]
go

CREATE TABLE [Books]
(
 [BookID]       bigint identity(1,1) NOT NULL ,
 [GenreID]      bigint NOT NULL ,
 [Name]         varchar(255) NOT NULL ,
 [Description]  varchar(max) NOT NULL ,
 [Year]         int NOT NULL ,
 [ISBN]         varchar(20) NOT NULL ,
 [Izdatelstvo]  varchar(50) NOT NULL ,
 [BarCode_GUID] varchar(50) NOT NULL ,

 CONSTRAINT [PK_Books] PRIMARY KEY CLUSTERED ([BookID] ASC),
 CONSTRAINT [FK_Book_Genre_Genre] FOREIGN KEY ([GenreID])  REFERENCES [Genres]([GenreID])
);
GO
--Сделал индекс для более быстрого поиска штрих-кода
CREATE NONCLUSTERED INDEX [IX_Books_BarCodeGUID] ON [Books] ( [BarCode_GUID] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_Books_Genres] ON [Books] ( [GenreID] ASC)
GO

--Двух книг с одним ISBN быть не может - этот индекс уникальный
create UNIQUE nonclustered index [IX_Books_ISBN] on [Books] ([ISBN] ASC)
go

create table [BooksAuthors]
(
  [BookAuthorID] bigint identity (1,1) not null,
  [BookID] bigint,
  [AuthorID] bigint,
  CONSTRAINT [PK_BookAuthorID] PRIMARY KEY CLUSTERED ([BookAuthorID] ASC),
)
go

create table [BooksSaldo] 
(
  [BookSaldoID] bigint identity (1,1) not null,
  [DateSaldo] datetime2 not null,
  [BookID]    bigint not null,
  [QtyIn]     int not null,
  [QtyOut]    int not null,
  [Saldo]     int not null
  CONSTRAINT [PK_BookSaldo] PRIMARY KEY CLUSTERED ([BookSaldoID] ASC),
  CONSTRAINT [FK_BookSaldo_BookID] FOREIGN KEY ([BookID])  REFERENCES [Books]([BookID])

)
go

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
 [DateBorn]            datetime2 not null,
 [Address]             varchar(200) NOT NULL ,
 [Phone]               varchar(20) NOT NULL ,
 [ReaderTicketBarcode] varchar(50) NOT NULL ,


 CONSTRAINT [PK_Readers] PRIMARY KEY CLUSTERED ([ReaderID] ASC)
);
GO
CREATE NONCLUSTERED INDEX [IX_Readers_FIO] ON [Readers] ( [FIO] ASC)
GO
CREATE NONCLUSTERED INDEX [IX_Readers_Phone] ON [Readers] ( [Phone] ASC)
GO
CREATE NONCLUSTERED INDEX [IX_Readers_Barcode] ON [Readers] ( [ReaderTicketBarcode] ASC)
GO

-- Читателем библиотеки может быть человек старше 18 лет.
ALTER TABLE [Readers] 
	ADD CONSTRAINT Readers_DateBorn 
		CHECK (datediff(yy, DateBorn, getdate()) >=18);
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
 [Qty]        int not null,

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
 [Qty]           int not null,
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
 [Qty]        int not null,
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
--==== Необходимо создать тестовые данные ======== ---
if not exists(select * from Genres)
begin
	insert into Genres
	values ('Компьютеры'), ('Художественная литература'),('Sci-fiction')
end 

if not exists (select * from Books)
begin
   declare @computer_genre int = (select GenreID from Genres where Name='Компьютеры')
   declare @classic int = (select GenreID from Genres where Name='Художественная литература')
   declare @sci int = (select GenreID from Genres where Name='Sci-fiction')

  insert Books   
   values (@computer_genre,'Алгоритмы на Java','Самая важная информация об алгоритмах и структурах данных',2013,'978-5-8459-1781-2','Addison-Wesley','9 785845 917812')
         ,(@computer_genre, 'Ремесло программиста','Перед вами книга по выживанию в условиях промышленного производства ПО',2009,'978-5-93286-127-1','Символ','9 785932 861271')
         ,(@computer_genre, 'Мифический человеко-месяц','Библия разработчиков написаная еще в 1975 году',2010,'5-93286-005-7','Символ','9 785932 860052')
         ,(@computer_genre, 'MS SQL 2012 - Оконные функции','Подробное руководство по применению оконных функций',2013,'978-5-7502-0416-8','Символ','9 785750 204168')
		 ,(@classic,'Путешествие в Икстлан','Дон Хуан открывает Кастанеде путь Воина',2006,'5-91250-072-1','София','9 785912 500725')
		 ,(@sci,'Война с саламандрами', 'В поисках жемчуга капитан Ван Тох обнаруживает возле островов Тихого океана необычных существ. Они похожи на саламандр, но обладают разумоми, как выяснилось, быстро обучаются.',1936,'978-5-04-155105-6','Эксмо','978-5-04-155105-6')
		 ,(@sci,'Задача трех тел', 'В те времена, когда Китай переживал последствия жестокой «культурной революции», в ходе секретного военного проекта в космос были посланы сигналы, чтобы установить контакт с инопланетным разумом.',2006,'9781784971595','Эксмо','9781784971595')
 
 insert into Authors 
		  values ('Роберт Сэджвик','1946-12-20', null, 'американский учёный в области информатики, профессор Принстонского университета'
		  ,'https://ru.wikipedia.org/wiki/%D0%A1%D0%B5%D0%B4%D0%B6%D0%B2%D0%B8%D0%BA,_%D0%A0%D0%BE%D0%B1%D0%B5%D1%80%D1%82')

         , ('Фредерик Брукс','1931-04-19', null, 'американский учёный в области теории вычислительных систем'
		  ,'https://ru.wikipedia.org/wiki/%D0%91%D1%80%D1%83%D0%BA%D1%81,_%D0%A4%D1%80%D0%B5%D0%B4%D0%B5%D1%80%D0%B8%D0%BA')
		 , ('Карлос Кастанеда','1925-12-25','1998-04-27','американский писатель, доктор философии по антропологии, этнограф, мыслитель эзотерической ориентации и мистик, автор 12 томов книг-бестселлеров, разошедшихся тиражом в 28 миллионов экземпляров на 17 языках'
		     ,'https://ru.wikipedia.org/wiki/%D0%9A%D0%B0%D1%81%D1%82%D0%B0%D0%BD%D0%B5%D0%B4%D0%B0,_%D0%9A%D0%B0%D1%80%D0%BB%D0%BE%D1%81')
	     , ('Карел Чапек','1890-01-09','1938-12-25','чешский писатель, прозаик и драматург, переводчик, фантаст','https://ru.wikipedia.org/wiki/%D0%A7%D0%B0%D0%BF%D0%B5%D0%BA,_%D0%9A%D0%B0%D1%80%D0%B5%D0%BB')		   
	     , ('Лю Ци Син','1963-07-23',null,'итайский писатель-фантаст, считающийся лицом китайской фантастики, а также самым плодовитым и популярным фантастом Китая','https://ru.wikipedia.org/wiki/%D0%9B%D1%8E_%D0%A6%D1%8B%D1%81%D0%B8%D0%BD%D1%8C')		   
      
insert into BooksAuthors
         values ((select BookID from Books where ISBN='978-5-8459-1781-2'),(select AuthorID from Authors where FIO='Роберт Сэджвик'))
		       , ((select BookID from Books where ISBN='5-93286-005-7'),(select AuthorID from Authors where FIO='Фредерик Брукс'))
		       , ((select BookID from Books where ISBN='5-91250-072-1'),(select AuthorID from Authors where FIO='Карлос Кастанеда'))
		       , ((select BookID from Books where ISBN='978-5-04-155105-6'),(select AuthorID from Authors where FIO='Карел Чапек'))
			   , ((select BookID from Books where ISBN='9781784971595'),(select AuthorID from Authors where FIO='Лю Ци Син'))
end 