/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
--Получилось весьма "развестисто" и даже очень даже аляписто, я просто не знаю как можно красивее сделать

/*
Table 'Worktable'. Scan count 32326, logical reads 249779, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 2220, logical reads 499944, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Invoices'. Scan count 2, logical reads 22800, physical reads 3, read-ahead reads 9283, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Customers'. Scan count 1, logical reads 40, physical reads 1, read-ahead reads 31, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 31688 ms,  elapsed time = 38763 ms.
*/
SELECT Invoices.InvoiceId, Invoices.InvoiceDate, cust.CustomerName , trans.TransactionAmount,
	(SELECT sum(inr.TransactionAmount)
	FROM Sales.CustomerTransactions as inr
		join Sales.Invoices as InvoicesInner ON 
			InvoicesInner.InvoiceID = inr.InvoiceID
	WHERE  (Month(InvoicesInner.InvoiceDate)  + Year(InvoicesInner.InvoiceDate) * 100) <=( Month(Invoices.InvoiceDate) 
		+ Year(Invoices.InvoiceDate) * 100)
		and InvoicesInner.InvoiceDate>='2015-01-01'
		) AS UpperItog
FROM Sales.Invoices as Invoices
join Sales.CustomerTransactions as trans ON Invoices.InvoiceID = trans.InvoiceID
join Sales.Customers cust (nolock) on Invoices.CustomerID = cust.CustomerID
 
WHERE Invoices.InvoiceDate >= '2015-01-01'
ORDER BY Invoices.InvoiceId, Invoices.InvoiceDate;

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
/*
SQL Server parse and compile time: 
   CPU time = 15 ms, elapsed time = 377 ms.

(затронуто строк: 31440)
Table 'Worktable'. Scan count 18, logical reads 67049, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 5, logical reads 1126, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 11400, physical reads 3, read-ahead reads 8840, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Customers'. Scan count 1, logical reads 40, physical reads 1, read-ahead reads 31, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 453 ms,  elapsed time = 6101 ms.
*/
SELECT Invoices.InvoiceId, Invoices.InvoiceDate, cust.CustomerName , trans.TransactionAmount,

	sum(trans.TransactionAmount) over (order by  Month(Invoices.InvoiceDate) 
		+ Year(Invoices.InvoiceDate) * 100 ) AS UpperItog

FROM Sales.Invoices as Invoices
join Sales.CustomerTransactions as trans ON Invoices.InvoiceID = trans.InvoiceID
join Sales.Customers cust (nolock) on Invoices.CustomerID = cust.CustomerID
 
WHERE Invoices.InvoiceDate >= '2015-01-01'
ORDER BY Invoices.InvoiceId, Invoices.InvoiceDate;

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

WITH MonthSales
AS (	-- Вытащим все товары и поставим количество по месяцам
    SELECT si.StockItemName
			,	SUM(il.Quantity)		AS [QNTY]
			,	MONTH(i.InvoiceDate)	AS [Month]
    FROM Sales.InvoiceLines il
			JOIN [Sales].[Invoices] i ON il.InvoiceID = i.InvoiceID 
			JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
	WHERE i.InvoiceDate >='20160101' and  i.InvoiceDate<'2017-01-01'
    GROUP BY si.StockItemName, MONTH(i.InvoiceDate)
),
SalesNum
AS (	-- отсортируем товары по сумме и месяцу + пронумеруем
    SELECT		MonthSales.StockItemName 
			,	MonthSales.QNTY
			,	MonthSales.[Month]
			,	ROW_NUMBER() OVER(PARTITION BY MonthSales.[Month] ORDER BY MonthSales.QNTY DESC) AS [RN]
    FROM MonthSales
)	-- выберем больше или равное 2
	SELECT		Itog.StockItemName	AS Stock	
			,	[Month]				AS Month
			,	Itog.QNTY			
	FROM	SalesNum Itog
	WHERE Itog.RN <= 2
	ORDER BY Itog.[Month], Itog.QNTY DESC;

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT		si.StockItemID																			
		,	si.StockItemName 																		
		,	si.Brand																				
		,	ROW_NUMBER() OVER(PARTITION BY LEFT(si.StockItemName, 1) ORDER BY si.StockItemName) 	AS	NumFirstSymbol
		,	COUNT(*) OVER()																			AS	TotalLines
		,	COUNT(*) OVER(PARTITION BY LEFT(si.StockItemName, 1)) 									AS	TotalLinewFirstSymbol
		,	LEAD(si.StockItemID) OVER(ORDER BY si.StockItemName)									AS	ID_Next
		,	LAG(si.StockItemID) OVER(ORDER BY si.StockItemName)			 							AS	ID_PAST
		,	LAG(si.StockItemName, 2, 'No items') OVER(ORDER BY si.StockItemName)					AS	ID_PAST_2
		,	NTILE(30) OVER(ORDER BY si.TypicalWeightPerUnit)										AS	GROUP_30
FROM Warehouse.StockItems si
ORDER BY si.StockItemName;

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT		p.PersonID
       ,	p.FullName 
       ,	c.CustomerID
       ,	c.CustomerName
       ,	r.TransactionDate
       ,	r.TransactionAmount
FROM
(
    SELECT		ct.CustomerID
           ,	i.SalespersonPersonID
           ,	ct.TransactionDate
           ,	ct.TransactionAmount
           ,	ROW_NUMBER() OVER(PARTITION BY SalespersonPersonID ORDER BY TransactionDate DESC) AS RM
    FROM Sales.CustomerTransactions ct
         INNER JOIN Sales.Invoices i ON ct.InvoiceID = i.InvoiceID
) AS r
	JOIN Application.People p ON r.SalespersonPersonID = p.PersonID
	JOIN Sales.Customers c ON r.CustomerID = c.CustomerID
WHERE r.RM = 1;

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT		c.CustomerID
		,	c.CustomerName
		,	subq.StockItemID
		,	subq.StockItemName
		,	subq.UnitPrice
		,	subq.DateInVoice
FROM
(
    SELECT		i.CustomerID
           ,	il.StockItemID
           ,	si.StockItemName
           ,	si.UnitPrice
           ,	MAX(i.InvoiceDate) DateInVoice
           ,	ROW_NUMBER() OVER(PARTITION BY i.CustomerID ORDER BY si.UnitPrice DESC) AS [RN]
    FROM Sales.InvoiceLines il
         JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
         JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
	GROUP BY i.CustomerID
           ,	il.StockItemID
           ,	si.StockItemName
           ,	si.UnitPrice
) AS subq
	JOIN Sales.Customers c ON subq.CustomerID = c.CustomerID
WHERE subq.RN <= 2;