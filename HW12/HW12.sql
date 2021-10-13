/*Написание хранимых процедур 

Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.*/
use WideWorldImporters;

/* 1. Написать функцию возвращающую Клиента с наибольшей суммой покупки.*/
create function [dbo].[MaxBuySumClient]()
RETURNS int  
WITH EXECUTE AS CALLER  
AS  
BEGIN 
    declare @CUSTOMER int
	declare @Sum decimal
	select top 1 @CUSTOMER = i.CustomerID, @Sum = Sum (il.UnitPrice * il.Quantity)  
	from 
	Sales.Invoices i
	join Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID 
	group by i.CustomerID
	order by 2 desc
	return @CUSTOMER
end 
go
select  dbo.MaxBuySumClient() as MaxBuySumClientID
go

/* 2. Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту. 
	Использовать таблицы : Sales.Customers Sales.Invoices Sales.InvoiceLines*/

create procedure dbo.ClientSumBuy (@CustomerID int)
WITH EXECUTE AS CALLER
as 
begin
    select  Sum (il.UnitPrice * il.Quantity)  
	from 
	Sales.Invoices i
	join Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID 
	where i.CustomerID = @CustomerID
end 
go
exec dbo.ClientSumBuy @CustomerID=182
go
/* 3. Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему. */

USE [WideWorldImporters]
GO
CREATE FUNCTION Sales.F_CustomerSumma(@CustomerID int)
RETURNS DECIMAL(18,2)
WITH EXECUTE AS OWNER
AS
BEGIN
RETURN
	(SELECT	SUM(Sales.InvoiceLines.Quantity*Sales.InvoiceLines.UnitPrice) as SUMMA
FROM	     Sales.Invoices 
        join Sales.InvoiceLines ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID 
		join Sales.Customers ON Sales.Invoices.CustomerID = Sales.Customers.CustomerID
WHERE	Sales.Customers.CustomerID = @CustomerID)
END
GO
USE WideWorldImporters;  
GO  

CREATE PROCEDURE Sales.P_CustomerSumma     
    @CustomerID int   
AS   
SET NOCOUNT ON;  
SELECT	SUM(Sales.InvoiceLines.Quantity*Sales.InvoiceLines.UnitPrice) as SUMMA
FROM	     Sales.Invoices 
        join Sales.InvoiceLines ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID 
		join Sales.Customers ON Sales.Invoices.CustomerID = Sales.Customers.CustomerID
WHERE	Sales.Customers.CustomerID = @CustomerID
RETURN
GO 
--Сервер не держит в буффере предыдущие запуски функций, в отличии от процедур, поэтому хранимые процедуры обычно выполняются быстрее, чем обычные SQL-инструкции.
--Код процедур компилируется один раз при первом ее запуске, а затем сохраняется в скомпилированной форме.

/* 4. Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла.*/


CREATE FUNCTION Sales.Invoices_for_customer(@customerid int)  
RETURNS TABLE  
AS  
RETURN  
(SELECT	Sales.Invoices.InvoiceID, Sales.Invoices.InvoiceDate, SUM(Sales.InvoiceLines.Quantity*Sales.InvoiceLines.UnitPrice) as SUMMA
FROM	Sales.Invoices INNER JOIN
        Sales.InvoiceLines ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID INNER JOIN
        Sales.Customers ON Sales.Invoices.CustomerID = Sales.Customers.CustomerID
WHERE	Sales.Customers.CustomerID = @CustomerID
GROUP BY Sales.Invoices.InvoiceID, Sales.Invoices.InvoiceDate
)
GO
SELECT T.CustomerID, T.CustomerName, S.InvoiceID, S.InvoiceDate, S.SUMMA
FROM  Sales.Customers as T
CROSS APPLY Sales.Invoices_for_customer(T.CustomerID) AS S
ORDER BY T.CustomerID, S.InvoiceDate
go
/* 5. Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. */
--READ COMITTED 
/*Большинство промышленных СУБД, в частности, Microsoft SQL Server, PostgreSQL и Oracle, по 
умолчанию используют именно этот уровень. На этом уровне обеспечивается защита от чернового, «грязного» чтения, 
тем не менее, в процессе работы одной транзакции другая может быть успешно завершена и сделанные ею изменения зафиксированы. 
В итоге первая транзакция будет работать с другим набором данных.
Реализация завершённого чтения может основываться на одном из двух подходов: блокировании или версионности. */

