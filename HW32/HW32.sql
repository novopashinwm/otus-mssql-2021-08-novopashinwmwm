/****** Делаем анализ базы данных из первого модуля, выбираем таблицу и делаем ее секционирование,
с переносом данных по секциям (партициям) - исходя из того, что таблица большая, 
пишем скрипты миграции в секционированную таблицу   ******/

select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

/*** Будем партиционировать таблицу [Warehouse].[StockItemTransactions] по ключу [TransactionOccurredWhen] ***/
SELECT  MIN([TransactionOccurredWhen]), MAX([TransactionOccurredWhen])
  FROM [WideWorldImporters].[Warehouse].[StockItemTransactions]
GO

ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [YearData]
GO

ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'Years',
FILENAME = N'F:\MS_SQL_Server\MSSQL14.SQL2017\MSSQL\DATA\WideWorldImporters_Yeardata.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP [YearData]
GO

CREATE PARTITION FUNCTION [fnYearPartition](DATETIME2(7)) AS RANGE RIGHT FOR VALUES
('2012-01-01 00:00:00.0000000','2013-01-01 00:00:00.0000000', '2014-01-01 00:00:00.0000000',
'2015-01-01 00:00:00.0000000', '2016-01-01 00:00:00.0000000', '2017-01-01 00:00:00.0000000',
'2018-01-01 00:00:00.0000000', '2019-01-01 00:00:00.0000000', '2020-01-01 00:00:00.0000000', 
'2021-01-01 00:00:00.0000000');																																																									
GO

CREATE PARTITION SCHEME [schmYearPartition] AS PARTITION [fnYearPartition] 
ALL TO ([YearData])
GO

CREATE TABLE [Warehouse].[StockItemTransactionsYears](
	[StockItemTransactionID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[TransactionTypeID] [int] NOT NULL,
	[CustomerID] [int] NULL,
	[InvoiceID] [int] NULL,
	[SupplierID] [int] NULL,
	[PurchaseOrderID] [int] NULL,
	[TransactionOccurredWhen] [datetime2](7) NOT NULL,
	[Quantity] [decimal](18, 3) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL
	) ON [schmYearPartition]([TransactionOccurredWhen])---в схеме [schmYearPartition] по ключу [TransactionOccurredWhen]
GO
ALTER TABLE [Warehouse].[StockItemTransactionsYears] ADD CONSTRAINT PK_Warehouse_StockItemTransactionsYears 
PRIMARY KEY CLUSTERED  (TransactionOccurredWhen, StockItemTransactionID)
 ON [schmYearPartition]([TransactionOccurredWhen]);
 go
 INSERT INTO [Warehouse].[StockItemTransactionsYears](
	[StockItemTransactionID],
	[StockItemID],
	[TransactionTypeID],
	[CustomerID],
	[InvoiceID],
	[SupplierID],
	[PurchaseOrderID],
	[TransactionOccurredWhen],
	[Quantity],
	[LastEditedBy],
	[LastEditedWhen])
	SELECT * FROM [Warehouse].[StockItemTransactions];
GO

/*** Добавилась ещё одна секционированная таблица. ***/
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1
go
/*** И вот так в ней распределились по партициям данные. ***/
SELECT  $PARTITION.fnYearPartition(TransactionOccurredWhen) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(TransactionOccurredWhen)
		,MAX(TransactionOccurredWhen) 
FROM [Warehouse].[StockItemTransactionsYears]
GROUP BY $PARTITION.fnYearPartition(TransactionOccurredWhen) 
ORDER BY Partition ;  
go