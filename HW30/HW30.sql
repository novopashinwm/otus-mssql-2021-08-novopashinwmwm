use WideWorldImporters
go
--SET STATISTICS IO, TIME ON

Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM
	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
		JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
		JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
WHERE
	Inv.BillToCustomerID != ord.CustomerID
	AND
	(
	Select
		SupplierId
	FROM
		Warehouse.StockItems AS It
	Where
		It.StockItemID = det.StockItemID
	) = 12
	AND
	(
	SELECT
		SUM(Total.UnitPrice*Total.Quantity)
	FROM
		Sales.OrderLines AS Total
			Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
	WHERE
		ordTotal.CustomerID = Inv.CustomerID
	) > 250000
	AND
	DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

/*
Так же очистим кэш и запустим запрос
Получим 6 секунд и 3619 строк
https://statisticsparser.com
показывает 14 сканов и 77,047 логических чтений
При повторном запуске данные выдаются мгновенно - имеем кэш
Если сбросим - получим те же 6 секунд
SQL Server Execution Times:
   CPU time = 1047 ms,  elapsed time = 6391 ms.
Первое, что смущает, это
(
Select
	SupplierId
FROM
	Warehouse.StockItems AS It
Where
	It.StockItemID = det.StockItemID
) = 12
Попробуем сделать join таблицы Warehouse.StockItems
И испробуем 2 варианта.
Оставим = 12 в WHERE и добавим его в ON
*/

--1
Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM
	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
		JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
		JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
		JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID
WHERE
	Inv.BillToCustomerID != ord.CustomerID
	AND
	It.SupplierId = 12
	AND
	(
	SELECT
		SUM(Total.UnitPrice*Total.Quantity)
	FROM
		Sales.OrderLines AS Total
			Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
	WHERE
		ordTotal.CustomerID = Inv.CustomerID
	) >= 250000
	AND
	DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--Получим 77397 логических чтений и 6700ms

--2
Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM
	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
		JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
		JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
		JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID AND It.SupplierId = 12
WHERE
	Inv.BillToCustomerID != ord.CustomerID
	AND
	(
	SELECT
		SUM(Total.UnitPrice*Total.Quantity)
	FROM
		Sales.OrderLines AS Total
			Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
	WHERE
		ordTotal.CustomerID = Inv.CustomerID
	) >= 250000
	AND
	DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--77176 чтений и 6314ms
--Пока что мы не особо в выигрыше, поскольку немного увеличилось чтений, но время стало ну совсем чуть-чуть быстрее

--Но если поменять местами stockitemstransactions и stockitems то

--3
Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM
	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
		JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
		--JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
		JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID AND It.SupplierId = 12
		JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
WHERE
	Inv.BillToCustomerID != ord.CustomerID
	AND
	(
	SELECT
		SUM(Total.UnitPrice*Total.Quantity)
	FROM
		Sales.OrderLines AS Total
			Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
	WHERE
		ordTotal.CustomerID = Inv.CustomerID
	) >= 250000
	AND
	DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--76681 чтенийи время 6435ms
--чтений меньше, времени чуть-чуть побольше

--Оставим пока-что второй вариант

/*
Далее смущает функция DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
Оба поля по таблицам - date
Функция возвращает 0, а это значит что дни одинаковы
Заменим просто на равенство
*/

Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM
	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
		JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
		JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
		JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID AND It.SupplierId = 12
WHERE
	Inv.BillToCustomerID != ord.CustomerID
	AND
	(
	SELECT
		SUM(Total.UnitPrice*Total.Quantity)
	FROM
		Sales.OrderLines AS Total
			Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
	WHERE
		ordTotal.CustomerID = Inv.CustomerID
	) >= 250000
	AND
	Inv.InvoiceDate = ord.OrderDate
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--Получили 6323ms но 109128 чтений

/*
Похоже самой большой проблемой является
(
SELECT
	SUM(Total.UnitPrice*Total.Quantity)
FROM
	Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
WHERE
	ordTotal.CustomerID = Inv.CustomerID
) >= 250000
Надо от него избавляться
Данный подзапрос фильтрует по сумме стоимости * количество товара в заказах за все время по нашим клиентам
Попробуем для начала просто его отделить и построить
*/

SELECT
	ordTotal.CustomerID,
	SUM(Total.UnitPrice*Total.Quantity) as sumtotal
FROM
	Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
GROUP BY
	ordTotal.CustomerID

--на выходе имеем 633 строки
--но нам надо отделить больше или равно 250000
--в этой ситуации вижу 2 варианта
--Или оставлять с group by и having или попробовать воспользоваться оконной функцией но нужен будет distinct

SELECT
	distinct ordTotal.CustomerID,
	SUM(Total.UnitPrice*Total.Quantity) over (partition by ordTotal.CustomerID) as sumtotal
FROM
	Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID

-339ms против 296ms

--Попробуем построить CTE

--1
;with CTE_SUM (CustomerID, sumtotal)
as
(
SELECT
	ordTotal.CustomerID,
	SUM(Total.UnitPrice*Total.Quantity) as sumtotal
FROM
	Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
GROUP BY
	ordTotal.CustomerID
HAVING SUM(Total.UnitPrice*Total.Quantity) >= 250000
)
Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM
	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
		JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
		JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
		JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID AND It.SupplierId = 12
		JOIN CTE_SUM ON CTE_SUM.CustomerID = Inv.CustomerID
WHERE
	Inv.BillToCustomerID != ord.CustomerID
	AND
	Inv.InvoiceDate = ord.OrderDate
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--110866 чтений и 6164ms



--2
;with CTE_SUM (CustomerID, sumtotal)
as
(
SELECT
	distinct ordTotal.CustomerID,
	SUM(Total.UnitPrice*Total.Quantity) over (partition by ordTotal.CustomerID) as sumtotal
FROM
	Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
)
Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM
	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
		JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
		JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
		JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID AND It.SupplierId = 12
		JOIN CTE_SUM ON CTE_SUM.CustomerID = Inv.CustomerID AND CTE_SUM.sumtotal >= 250000
WHERE
	Inv.BillToCustomerID != ord.CustomerID
	AND
	Inv.InvoiceDate = ord.OrderDate
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--12546 чтений и 5830ms

--ВЫБОР ОЧЕВИДЕН!!!

--Вариант 2

--В ИТОГЕ МЫ ПОЛУЧАЕМ

;with CTE_SUM (CustomerID, sumtotal)
as
(
SELECT
	distinct ordTotal.CustomerID,
	SUM(Total.UnitPrice*Total.Quantity) over (partition by ordTotal.CustomerID) as sumtotal
FROM
	Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
)
Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM
	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
		JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
		JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
		JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID AND It.SupplierId = 12
		JOIN CTE_SUM ON CTE_SUM.CustomerID = Inv.CustomerID AND CTE_SUM.sumtotal >= 250000
WHERE
	Inv.BillToCustomerID != ord.CustomerID
	AND
	Inv.InvoiceDate = ord.OrderDate
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--Можем так же избавиться от WHERE

;with CTE_SUM (CustomerID, sumtotal)
as
(
SELECT
	distinct ordTotal.CustomerID,
	SUM(Total.UnitPrice*Total.Quantity) over (partition by ordTotal.CustomerID) as sumtotal
FROM
	Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
)
Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM
	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID AND Inv.BillToCustomerID != ord.CustomerID AND Inv.InvoiceDate = ord.OrderDate
		JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
		JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
		JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID AND It.SupplierId = 12
		JOIN CTE_SUM ON CTE_SUM.CustomerID = Inv.CustomerID AND CTE_SUM.sumtotal >= 250000
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--Чтения не изменились, но времени чуть убавил - 5677ms

--В плане запроса нигде не увидел восклицательных знаков.

--Подведу итог

--Получили читаемый запрос

;with CTE_SUM (CustomerID, sumtotal)
as
(
SELECT
	distinct ordTotal.CustomerID,
	SUM(Total.UnitPrice*Total.Quantity) over (partition by ordTotal.CustomerID) as sumtotal
FROM
	Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
)
Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM
	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID AND Inv.BillToCustomerID != ord.CustomerID AND Inv.InvoiceDate = ord.OrderDate
		JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
		JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
		JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID AND It.SupplierId = 12
		JOIN CTE_SUM ON CTE_SUM.CustomerID = Inv.CustomerID AND CTE_SUM.sumtotal >= 250000
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--Немного ускорили время выполнения и уменьшили кол-во чтений примерно в 5 раз