/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
select * from (
    SELECT 
       DATEFROMPARTS(YEAR(I.InvoiceDate),MONTH(I.InvoiceDate),1) InvoiceMonth
	 , Replace(REPLACE(cust.CustomerName,'Tailspin Toys (',''),')','') as FullName 
    FROM Sales.Invoices AS I
	JOIN Sales.Customers cust on I.CustomerID = cust.CustomerID
	where cust.CustomerID in (2,3,4,5,6)
) as s
pivot (
count (FullName)
for FullName in ([Peeples Valley, AZ],[Medicine Lodge, KS],[Gasport, NY],[Sylvanite, MT],[Jessie, ND]))
as pvt 
order by InvoiceMonth
/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
SELECT CustomerName, AddressLine
FROM (
select cust.CustomerName 
	, cust.DeliveryAddressLine1
	, cust.DeliveryAddressLine2
	, cust.PostalAddressLine1
	, cust.PostalAddressLine2
	from Sales.Customers cust 
where cust.CustomerName like ('%Tailspin Toys%') ) 
as peop
UNPIVOT
(AddressLine For Name In (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2 )) as  inp;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/
SELECT CountryID, CountryName, Code
FROM (
select ctr.CountryID
	, ctr.CountryName
	, cast (ctr.IsoAlpha3Code as varchar) as IsoAlpha3Code 
	, cast (ctr.IsoNumericCode as varchar) as IsoNumericCode 
	from Application.Countries ctr )
as countries
UNPIVOT
(Code For Name In (IsoAlpha3Code, IsoNumericCode )) as  inp;


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT C.CustomerID, C.CustomerName, O.StockItemID, O.UnitPrice, O.OrderDate
FROM Sales.Customers C
OUTER APPLY (SELECT TOP 2 OL.StockItemID, OL.UnitPrice, O.OrderDate
                FROM 
				Sales.Orders O
				join Sales.OrderLines OL on O.OrderID = OL.OrderID
                WHERE O.CustomerID = C.CustomerID
                ORDER BY OL.UnitPrice DESC) AS O
ORDER BY C.CustomerName;
