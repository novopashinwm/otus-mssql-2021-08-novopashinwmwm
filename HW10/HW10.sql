use WideWorldImporters;
/*1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers*/
/*insert 
Purchasing.Suppliers
	values (next value for Sequences.SupplierID,'')*/
INSERT INTO [Purchasing].[Suppliers]
          ([SupplierName], [SupplierCategoryID] ,[PrimaryContactPersonID] ,[AlternateContactPersonID] ,[DeliveryMethodID] ,[DeliveryCityID] ,[PostalCityID] ,[PaymentDays] ,[PhoneNumber] ,[FaxNumber] ,[WebsiteURL] ,[DeliveryAddressLine1] ,[DeliveryPostalCode] ,[PostalAddressLine1] ,[PostalPostalCode] ,[LastEditedBy])
	 OUTPUT inserted.[SupplierName]
     VALUES
           ('Test_01' ,7 ,21 ,21 ,7 ,38171 ,38171 ,14 ,'777-777-777' ,'777-777-777' ,'http:\\' ,'unit_01' ,'46077' ,'ADR' ,'46077' ,1),
           ('Test_02' ,7 ,21 ,21 ,7 ,38171 ,38171 ,14 ,'777-777-777' ,'777-777-777' ,'http:\\' ,'unit_01' ,'46077' ,'ADR' ,'46077' ,1),
           ('Test_03' ,7 ,21 ,21 ,7 ,38171 ,38171 ,14 ,'777-777-777' ,'777-777-777' ,'http:\\' ,'unit_01' ,'46077' ,'ADR' ,'46077' ,1),
           ('Test_04' ,7 ,21 ,21 ,7 ,38171 ,38171 ,14 ,'777-777-777' ,'777-777-777' ,'http:\\' ,'unit_01' ,'46077' ,'ADR' ,'46077' ,1),
           ('Test_05' ,7 ,21 ,21 ,7 ,38171 ,38171 ,14 ,'777-777-777' ,'777-777-777' ,'http:\\' ,'unit_01' ,'46077' ,'ADR' ,'46077' ,1)

/*2. Удалите одну запись из Customers, которая была вами добавлена*/

DELETE FROM [Purchasing].[Suppliers]
      WHERE [Purchasing].[Suppliers].[SupplierName] = 'Test_01'

/*3. Изменить одну запись, из добавленных через UPDATE*/

UPDATE [Purchasing].[Suppliers]
   SET [PhoneNumber] = '888-888-888'
 WHERE [Purchasing].[Suppliers].[SupplierName] = 'Test_02'

/*4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть*/

MERGE [Purchasing].[Suppliers] as T
USING (SELECT U.[SupplierName] FROM [Purchasing].[Suppliers] AS U WHERE U.[SupplierName] = 'Test_02') AS U
ON T.[SupplierName] = U.[SupplierName]
WHEN Matched THEN
UPDATE SET [FaxNumber] = '999-888-888'
WHEN NOT Matched THEN
INSERT ([SupplierName], [SupplierCategoryID] ,[PrimaryContactPersonID] ,[AlternateContactPersonID] ,[DeliveryMethodID] ,[DeliveryCityID] ,[PostalCityID] ,[PaymentDays] ,[PhoneNumber] ,[FaxNumber] ,[WebsiteURL] ,[DeliveryAddressLine1] ,[DeliveryPostalCode] ,[PostalAddressLine1] ,[PostalPostalCode] ,[LastEditedBy])
VALUES ('Test_08' ,7 ,21 ,21 ,7 ,38171 ,38171 ,14 ,'777-777-777' ,'777-777-777' ,'http:\\' ,'unit_01' ,'46077' ,'ADR' ,'46077' ,1);

/*5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert*/

exec master..xp_cmdshell 'bcp "[WideWorldImporters].[Sales].[Customers]" out  "d:\Projects\Customers.txt" -T -w -t"|", -S DESKTOP-28CMH10\SQL2017'

drop table if exists #Customers_COPY

CREATE TABLE #Customers_COPY(
	CustomerID int,
	CustomerName nvarchar(100),
	BillToCustomerID int ,
	CustomerCategoryID int ,
	BuyingGroupID int NULL,
	PrimaryContactPersonID int ,
	AlternateContactPersonID int NULL,
	DeliveryMethodID int ,
	DeliveryCityID int ,
	PostalCityID int ,
	CreditLimit decimal(18, 2) NULL,
	AccountOpenedDate date ,
	StandardDiscountPercentage decimal(18, 3) ,
	IsStatementSent bit ,
	IsOnCreditHold bit ,
	PaymentDays int ,
	PhoneNumber nvarchar(20) ,
	FaxNumber nvarchar(20) ,
	DeliveryRun nvarchar(5) NULL,
	RunPosition nvarchar(5) NULL,
	WebsiteURL nvarchar(256) ,
	DeliveryAddressLine1 nvarchar(60) ,
	DeliveryAddressLine2 nvarchar(60) NULL,
	DeliveryPostalCode nvarchar(10) ,
	DeliveryLocation geography NULL,
	PostalAddressLine1 nvarchar(60) ,
	PostalAddressLine2 nvarchar(60) NULL,
	PostalPostalCode nvarchar(10) ,
	LastEditedBy int ,
	ValidFrom datetime2(7),
	ValidTo datetime2(7))

BULK INSERT #Customers_COPY
				   FROM "C:\DATA\Customers.txt"
				   WITH 
					 (
						BATCHSIZE = 10, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '|,',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK
					  );
select Count(*) from #Customers_COPY

DROP TABLE IF EXISTS #Customers_COPY
