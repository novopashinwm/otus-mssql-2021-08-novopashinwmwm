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
  [SaldoBegin] int not null,
  [QtyIn]     int not null,
  [QtyOut]    int not null,
  [SaldoEnd] int not null,
  
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
 [UpdateUserID] bigint  NULL ,
 [UpdateDate]   datetime2  NULL ,
 
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

/*Добавим книги, авторов и связи авторов и книг
  при этом могут быть ситуации 
  Авторы             Книги
    1                 1
	1                 много
	много             1
	много             много

  */
if not exists (select * from Books)
begin
   declare @computer_genre int = (select GenreID from Genres where Name='Компьютеры')
   declare @classic int = (select GenreID from Genres where Name='Художественная литература')
   declare @sci int = (select GenreID from Genres where Name='Sci-fiction')

  insert Books   
   values (@computer_genre,'Алгоритмы на Java','Самая важная информация об алгоритмах и структурах данных',2013,'978-5-8459-1781-2','Addison-Wesley','9 785845 917812')
         ,(@computer_genre, 'Ремесло программиста','Перед вами книга по выживанию в условиях промышленного производства ПО',2009,'978-5-93286-127-1','Символ','9 785932 861271')
		 ,(@computer_genre, 'Код. Тайный язык информатики','Книга «Код» представляет собой увлекательное путешествие в прошлое — мир электрических устройств и телеграфных машин.',2019
			,'978-5-00117-545-2','Иванов, Фабер, Манн','978-5-00117-545-2')
         ,(@computer_genre, 'Мифический человеко-месяц','Библия разработчиков написаная еще в 1975 году',2010,'5-93286-005-7','Символ','9 785932 860052')
         ,(@computer_genre, 'MS SQL 2012 - Оконные функции','Подробное руководство по применению оконных функций',2013,'978-5-7502-0416-8','Символ','9 785750 204168')
		 ,(@classic,'Путешествие в Икстлан','Дон Хуан открывает Кастанеде путь Воина',2006,'5-91250-072-1','София','9 785912 500725')
		 ,(@classic,'Дни Турбиных','Действие начинается в 1918 году, когда из Киева уходят немецкие войска, оккупировавшие Украину. И их место занимают петлюровцы. В центре сюжета – семья русских интеллигентов Турбиных'
		     ,1926,'978-5-4467-2471-0','Domain Public','978-5-4467-2471-0')
         ,(@classic,'Мастер и Маргарита','блистательный шедевр, созданный Михаилом Булгаковым, завораживающая мистическая дьяволиада, обнажающая вечные темы любви, борьбы добра со злом, смерти и бессмертия'
		     ,1967,'978-5-699-45351-1','Domain Public','978-5-699-45351-1')
         ,(@classic,'Стихотворения','Полное собрание сочинений Александра Блока для 7-8 класса' ,2011,'978-5-699-45351-4','Domain Public','978-5-699-45351-4')
		 ,(@classic,'МОЖНО ЛИ ЗАБИТЬ ГВОЗДЬ В КОСМОСЕ','«Как попасть в отряд космонавтов?», «Что вы едите на борту космического корабля?», «Есть ли интернет на МКС?», «Плоская ли Земля?» — эти и другие вопросы постоянно задают космонавтам.' 
		   ,2019,'978-5-04-097778-9','Москва','978-5-04-097778-9')
		 ,(@sci,'Война с саламандрами', 'В поисках жемчуга капитан Ван Тох обнаруживает возле островов Тихого океана необычных существ. Они похожи на саламандр, но обладают разумоми, как выяснилось, быстро обучаются.',1936,'978-5-04-155105-6','Эксмо','978-5-04-155105-6')
		 ,(@sci,'Облачный атлас', '«Облачный атлас» подобен зеркальному лабиринту, в котором перекликаются, наслаиваясь друг на друга, шесть голосов.'
		   ,2016,'978-5-389-11221-6','Иностранка','978-5-389-11221-6')

		 ,(@sci,'Задача трех тел', 'В те времена, когда Китай переживал последствия жестокой «культурной революции», в ходе секретного военного проекта в космос были посланы сигналы, чтобы установить контакт с инопланетным разумом.',2006,'9781784971595','Эксмо','9781784971595')
		 ,(@sci,'Темный лес', 'Трисолярианский кризис продолжается. У землян есть 400 лет, чтобы предотвратить инопланетное вторжение. Но угроза полного уничтожения, вопреки ожиданиям, не объединяет человечество'
		    ,2006,'9780765377081','Эксмо','9780765377081')
 
	insert into Authors 
		  values ('Роберт Сэджвик','1946-12-20', null, 'американский учёный в области информатики, профессор Принстонского университета'
		  ,'https://ru.wikipedia.org/wiki/%D0%A1%D0%B5%D0%B4%D0%B6%D0%B2%D0%B8%D0%BA,_%D0%A0%D0%BE%D0%B1%D0%B5%D1%80%D1%82')

         , ('Фредерик Брукс','1931-04-19', null, 'американский учёный в области теории вычислительных систем'
		  ,'https://ru.wikipedia.org/wiki/%D0%91%D1%80%D1%83%D0%BA%D1%81,_%D0%A4%D1%80%D0%B5%D0%B4%D0%B5%D1%80%D0%B8%D0%BA')
		 , ('Карлос Кастанеда','1925-12-25','1998-04-27','американский писатель, доктор философии по антропологии, этнограф, мыслитель эзотерической ориентации и мистик, автор 12 томов книг-бестселлеров, разошедшихся тиражом в 28 миллионов экземпляров на 17 языках'
		     ,'https://ru.wikipedia.org/wiki/%D0%9A%D0%B0%D1%81%D1%82%D0%B0%D0%BD%D0%B5%D0%B4%D0%B0,_%D0%9A%D0%B0%D1%80%D0%BB%D0%BE%D1%81')
	     , ('Карел Чапек','1890-01-09','1938-12-25','чешский писатель, прозаик и драматург, переводчик, фантаст','https://ru.wikipedia.org/wiki/%D0%A7%D0%B0%D0%BF%D0%B5%D0%BA,_%D0%9A%D0%B0%D1%80%D0%B5%D0%BB')		   
	     , ('Лю Ци Син','1963-07-23',null,'китайский писатель-фантаст, считающийся лицом китайской фантастики, а также самым плодовитым и популярным фантастом Китая','https://ru.wikipedia.org/wiki/%D0%9B%D1%8E_%D0%A6%D1%8B%D1%81%D0%B8%D0%BD%D1%8C')		   
	     , ('Булгаков Михаил Афанасьевич','1891-05-03','1940-03-10','русский писатель советского периода, драматург, театральный режиссёр и актёр','https://ru.wikipedia.org/wiki/%D0%9B%D1%8E_%D0%A6%D1%8B%D1%81%D0%B8%D0%BD%D1%8C')		   
	     , ('Блок Александр Александрович','1880-11-16','1921-08-07','русский поэт, писатель, публицист, драматург, переводчик, литературный критик.'
		     ,'https://ru.wikipedia.org/wiki/%D0%91%D0%BB%D0%BE%D0%BA,_%D0%90%D0%BB%D0%B5%D0%BA%D1%81%D0%B0%D0%BD%D0%B4%D1%80_%D0%90%D0%BB%D0%B5%D0%BA%D1%81%D0%B0%D0%BD%D0%B4%D1%80%D0%BE%D0%B2%D0%B8%D1%87')		   
	     , ('Рязанский Сергей Николаевич','1974-11-13',null,'Первый в мире учёный — командир космического корабля'
		     ,'https://ru.wikipedia.org/wiki/%D0%A0%D1%8F%D0%B7%D0%B0%D0%BD%D1%81%D0%BA%D0%B8%D0%B9,_%D0%A1%D0%B5%D1%80%D0%B3%D0%B5%D0%B9_%D0%9D%D0%B8%D0%BA%D0%BE%D0%BB%D0%B0%D0%B5%D0%B2%D0%B8%D1%87')		   
  	     , ('Петцольд Чарльз','1953-02-02',null,'программист, автор технической литературы по компьютерной тематике. Популяризатор Microsoft Windows.'
		     ,'https://ru.wikipedia.org/wiki/%D0%9F%D0%B5%D1%82%D1%86%D0%BE%D0%BB%D1%8C%D0%B4,_%D0%A7%D0%B0%D1%80%D0%BB%D1%8C%D0%B7') 
  	     , ('Митчелл Дэвид','1969-01-12',null,'английский автор романов, два из которых вошли в шортлист Букеровской премии.'
		     ,'https://ru.wikipedia.org/wiki/%D0%9C%D0%B8%D1%82%D1%87%D0%B5%D0%BB%D0%BB,_%D0%94%D1%8D%D0%B2%D0%B8%D0%B4_(%D0%BF%D0%B8%D1%81%D0%B0%D1%82%D0%B5%D0%BB%D1%8C)') 
			    
	insert into BooksAuthors
         values ((select BookID from Books where ISBN='978-5-8459-1781-2'),(select AuthorID from Authors where FIO='Роберт Сэджвик'))
		       , ((select BookID from Books where ISBN='5-93286-005-7'),(select AuthorID from Authors where FIO='Фредерик Брукс'))
		       , ((select BookID from Books where ISBN='5-91250-072-1'),(select AuthorID from Authors where FIO='Карлос Кастанеда'))
		       , ((select BookID from Books where ISBN='978-5-04-155105-6'),(select AuthorID from Authors where FIO='Карел Чапек'))
			   , ((select BookID from Books where ISBN='9781784971595'),(select AuthorID from Authors where FIO='Лю Ци Син'))
			   , ((select BookID from Books where ISBN='9780765377081'),(select AuthorID from Authors where FIO='Лю Ци Син'))
			   , ((select BookID from Books where ISBN='978-5-4467-2471-0'),(select AuthorID from Authors where FIO='Булгаков Михаил Афанасьевич'))
			   , ((select BookID from Books where ISBN='978-5-699-45351-1'),(select AuthorID from Authors where FIO='Булгаков Михаил Афанасьевич'))
			   , ((select BookID from Books where ISBN='978-5-699-45351-4'),(select AuthorID from Authors where FIO='Блок Александр Александрович'))
			   , ((select BookID from Books where ISBN='978-5-04-097778-9'),(select AuthorID from Authors where FIO='Рязанский Сергей Николаевич'))
			   , ((select BookID from Books where ISBN='978-5-00117-545-2'),(select AuthorID from Authors where FIO='Петцольд Чарльз'))
			   , ((select BookID from Books where ISBN='978-5-389-11221-6'),(select AuthorID from Authors where FIO='Митчелл Дэвид'))

end 

-- Добавим записи библиотекарей
if not exists (select * from Users)
begin
    insert into Users values
	     ('vetoshkina52'), ('pushkina82')
end 

--Добавим 5 читалей
if not exists (select * from Readers) 
begin
   insert into Readers values 
            ('Сидоров Иван Петрович','2000-11-22','Коломна, ул. Дзержинского 5 кв. 12'   ,'+79151445517','0000001')
          , ('Епифанцев Владимир Егорович','1950-07-03','Коломна, ул. Кирова 31 кв. 01'  ,'+79032735267','0000002')
          , ('Навальный Алексей Михайлович','1976-06-15','Коломна, пр. Окский 7 кв. 01'  ,'+79264317721','0000003')
          , ('Трегубов Юрий Владимирович','1976-03-24' ,'Коломна, ул. Калинина 121 кв.41','+79069014769','0000004')
		  , ('Кипелов Антон Тихонович','1962-10-29' ,'Коломна, ул. Фрунзе 54, кв. 11'    ,'+79172023019','0000005')
         
end 

-- Добавим количество шкафов по жанрам
if not exists (select * from Cupboards)
begin
	insert into Cupboards ([Locate])
	     select [Name] from Genres
end 