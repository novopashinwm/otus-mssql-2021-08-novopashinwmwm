use WideWorldImporters;
go
/*Написать хранимую процедуру возвращающую Клиента с набольшей разовой суммой покупки.*/
CREATE procedure Sales.GetCustomerIdMaxSumma
WITH EXECUTE AS OWNER
AS
BEGIN

	SELECT TOP 1	Sales.Customers.CustomerID
		FROM		Sales.Invoices 
		            join Sales.InvoiceLines ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID 
					join Sales.Customers ON Sales.Invoices.CustomerID = Sales.Customers.CustomerID
		GROUP BY Sales.Customers.CustomerID, Sales.Customers.CustomerName
	ORDER BY SUM(Sales.InvoiceLines.Quantity*Sales.InvoiceLines.UnitPrice) DESC
END
GO
exec Sales.GetCustomerIdMaxSumma
go