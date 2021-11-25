/****** 1. Создайте очередь для формирования отчетов для клиентов по таблице Invoices.
    При вызове процедуры для создания отчета в очередь должна отправляться заявка.
2. При обработке очереди создавайте отчет по количеству заказов (Orders) по клиенту
   за заданный период времени и складывайте готовый отчет в новую таблицу.
3. Проверьте, что вы корректно открываете и закрываете диалоги и у нас они не копятся.   ******/
USE master
GO
ALTER DATABASE WideWorldImporters SET SINGLE_USER WITH ROLLBACK IMMEDIATE

USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER;

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

SELECT DATABASEPROPERTYEX ('WideWorldImporters','UserAccess');
SELECT is_broker_enabled FROM sys.databases WHERE name = 'WideWorldImporters';

ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];

ALTER DATABASE WideWorldImporters SET MULTI_USER WITH ROLLBACK IMMEDIATE
GO

USE WideWorldImporters;
GO
CREATE TABLE Sales.InvoicesReport ---создаём таблицу для отчётов
(CustomerID int,
OrdersQuantity int,
StartReportDate date,
StopReportDate date);

/*** CREATE MESSAGE TYPES AND CONTRACT ***/
CREATE MESSAGE TYPE
[//WWI/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML;

CREATE MESSAGE TYPE
[//WWI/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 

GO

CREATE CONTRACT [//WWI/SB/Contract]
      ([//WWI/SB/RequestMessage]
         SENT BY INITIATOR,
       [//WWI/SB/ReplyMessage]
         SENT BY TARGET);
GO

/*** CREATE QUEUE AND SERVICES ***/
CREATE QUEUE TargetQueueWWI;

CREATE SERVICE [//WWI/SB/TargetService]
       ON QUEUE TargetQueueWWI
       ([//WWI/SB/Contract]);
GO


CREATE QUEUE InitiatorQueueWWI;

CREATE SERVICE [//WWI/SB/InitiatorService]
       ON QUEUE InitiatorQueueWWI
       ([//WWI/SB/Contract]);
GO

/*** SEND MESSAGE ***/
CREATE PROCEDURE Sales.SendNewReportRequest
	@CustomerID INT, @startdate DATE, @stopdate DATE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @InitDlgHandle UNIQUEIDENTIFIER; 
	DECLARE @RequestMessage NVARCHAR(4000); 
	
	BEGIN TRAN 

	SELECT @RequestMessage = (SELECT CustomerID, @startdate AS startdate, @stopdate AS stopdate ---заявка на отчёт
		FROM Sales.Customers AS Cust
		WHERE CustomerID = @CustomerID
	    FOR XML AUTO, root('RequestMessage')); 
	
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//WWI/SB/InitiatorService]
	TO SERVICE
	'//WWI/SB/TargetService'
	ON CONTRACT
	[//WWI/SB/Contract]
	WITH ENCRYPTION=OFF; 

	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//WWI/SB/RequestMessage]
	(@RequestMessage);
	
	COMMIT TRAN 
END
GO

/*** REPLY MESSAGE ***/
CREATE PROCEDURE Sales.GetNewReportRequest
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER, 
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@CustomerID INT,
			@startdate DATE,
			@stopdate DATE,
			@xml XML; 
	
	BEGIN TRAN; 

	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.TargetQueueWWI; 

	SELECT @Message; 

	SET @xml = CAST(@Message AS XML); 

	--получаем CustomerID, startdate и stopdate из xml
    SELECT @CustomerID = R.Cu.value('@CustomerID','INT')
	FROM @xml.nodes('/RequestMessage/Cust') as R(Cu);
	
	SELECT @startdate = R.Cu.value('@startdate','DATE')
	FROM @xml.nodes('/RequestMessage/Cust') as R(Cu);
	
	SELECT @stopdate = R.Cu.value('@stopdate','DATE')
	FROM @xml.nodes('/RequestMessage/Cust') as R(Cu);

	--вставим отчёт в таблицу для отчётов
	IF EXISTS (SELECT * FROM Sales.Customers WHERE CustomerID = @CustomerID)
	BEGIN
		INSERT INTO Sales.InvoicesReport
                    (CustomerID ,
                     OrdersQuantity ,
                     StartReportDate,
                     StopReportDate)
VALUES (@CustomerID,
        (SELECT COUNT (Inv.OrderID) FROM Sales.Invoices Inv WHERE Inv.CustomerID=@CustomerID AND Inv.InvoiceDate BETWEEN @startdate AND @stopdate),
		@startdate,
		@stopdate);
	END;
	
	IF @MessageType=N'//WWI/SB/RequestMessage'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage> Message received </ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//WWI/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;--закроем диалог со стороны таргета
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; --в лог

	COMMIT TRAN;
END
GO

/*** GET REPLY MESSAGE ***/
CREATE PROCEDURE Sales.ConfirmReportRequest
AS
BEGIN
	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER, 
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 


		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueueWWI; 
		
		END CONVERSATION @InitiatorReplyDlgHandle;
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; 

	COMMIT TRAN; 
END

/*** EXEC ***/
SELECT * FROM Sales.InvoicesReport;

--Send message
EXEC Sales.SendNewReportRequest
	@CustomerID = 12, @startdate='2014-01-01', @stopdate='2015-01-01';

--в какой очереди окажется сообщение?
SELECT CAST(message_body AS XML),*
FROM dbo.InitiatorQueueWWI;

SELECT CAST(message_body AS XML),*
FROM dbo.TargetQueueWWI;

--Target
EXEC Sales.GetNewReportRequest;

--посмотрим текущие диалоги
SELECT	conversation_handle, 
		is_initiator, 
		s.name as 'local service', 
		far_service, 
		sc.name 'contract', 
		ce.state_desc
FROM sys.conversation_endpoints ce
LEFT JOIN sys.services s
	ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
	ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;

--Initiator
EXEC Sales.ConfirmReportRequest;

--есть ли открытые диалоги
SELECT conversation_handle, is_initiator, s.name as 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints ce
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;

--смотрим отчёт
SELECT * FROM Sales.InvoicesReport;

--текущие сообщения и сообщения с ошибками
SELECT * FROM sys.transmission_queue;