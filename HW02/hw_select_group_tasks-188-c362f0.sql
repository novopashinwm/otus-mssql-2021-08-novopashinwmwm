/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select wh.StockItemID, wh.StockItemName 
from
Warehouse.StockItems wh (nolock) where
wh.StockItemName like ('%urgent%') or  wh.StockItemName like ('Animal%')

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select sup.SupplierID, sup.SupplierName
from 
Purchasing.Suppliers (nolock) sup 
left join Purchasing.PurchaseOrders pur on pur.SupplierID = sup.SupplierID
where
pur.SupplierID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select distinct sor.OrderID, sor.OrderDate
, FORMAT( sor.OrderDate, 'MMMM', 'ru-ru' ) as [MONTH]
,DATEPART(QUARTER,sor.OrderDate) as  [QUARTER]
,DATEPART(WEEK, sor.OrderDate) / (52 /3) + 1 as [TRES]
, cust.CustomerName
from 
Sales.Orders sor (nolock)
join Sales.Customers cust (nolock) on sor.CustomerID = sor.CustomerID
join Sales.OrderLines sorl (nolock) on sor.OrderID = sorl.OrderID
where
(sorl.UnitPrice > 100
or sorl.Quantity > 20)
and not sorl.PickingCompletedWhen is null
order by  [QUARTER], [TRES],  sor.OrderDate
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select dm.DeliveryMethodName, o.ExpectedDeliveryDate, ps.SupplierName , ap.FullName from 
Purchasing.PurchaseOrders o (nolock)
join Application.DeliveryMethods dm (nolock) on o.DeliveryMethodID = dm.DeliveryMethodID
join Purchasing.Suppliers ps (nolock) on o.SupplierID = ps.SupplierID
join Application.People ap (nolock) on o.ContactPersonID = ap.PersonID
where
o.ExpectedDeliveryDate >= '20130101' and o.ExpectedDeliveryDate < '20130201'
and dm.DeliveryMethodName in ('Air Freight','Refrigerated Air Freight')
and o.IsOrderFinalized = 1
order by dm.DeliveryMethodName, o.ExpectedDeliveryDate, ps.SupplierName

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10 cust.CustomerName
, pers.FullName as SalesPersonName
from Sales.Orders (nolock) so
join Sales.Customers (nolock) cust on so.CustomerID = cust.CustomerID
join WideWorldImporters.Application.People (nolock) pers on so.SalespersonPersonID = pers.PersonID
order by so.OrderDate desc , so.OrderID desc, cust.CustomerName, SalesPersonName

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct cust.CustomerID , cust.CustomerName, cust.PhoneNumber 
from Sales.Orders (nolock) so
join Sales.OrderLines (nolock) sol on so.OrderID = sol.OrderID
join Warehouse.StockItems si (nolock) on si.StockItemID = sol.StockItemID
join Sales.Customers (nolock) cust on so.CustomerID = cust.CustomerID
where
si.StockItemName = 'Chocolate frogs 250g'
order by cust.CustomerName

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
  Year(si.InvoiceDate) as SALE_YEAR 
, MONTH(si.InvoiceDate) as SALE_MONTH
, avg(sl.UnitPrice) as avg_price
, sum (sl.Quantity * sl.UnitPrice) as sum_sales    
from
Sales.Invoices si (nolock)
join Sales.InvoiceLines sl (nolock) on si.InvoiceID = sl.InvoiceID

group by Year(si.InvoiceDate) , MONTH(si.InvoiceDate)

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
select 
case when mainQry.SALE_YEAR is null then years.year else mainQry.SALE_YEAR end SALES_YEAR 
,case when mainQry.SALE_MONTH is null then months.mounth else mainQry.SALE_MONTH end SALES_MONTH 
,case when mainQry.sum_sales is null then 0 else mainQry.sum_sales end sum_sales 
from
(values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) as months(mounth)
cross join (values (2010),(2011),(2012),(2014),(2015),(2016),(2017),(2018),(2019),(2020),(2021),(2022)) as years(year)
left join (select 
  Year(si.InvoiceDate) as SALE_YEAR 
, MONTH(si.InvoiceDate) as SALE_MONTH
, sum (Isnull(sl.Quantity * sl.UnitPrice,0)) as sum_sales    
from

Sales.Invoices si (nolock) 
left join Sales.InvoiceLines sl (nolock) on si.InvoiceID = sl.InvoiceID 
group by Year(si.InvoiceDate) , MONTH(si.InvoiceDate) 
having sum (sl.Quantity * sl.UnitPrice) > 10000) as mainQry on mainQry.SALE_YEAR = years.year and mainQry.SALE_MONTH = months.mounth
order by years.year, months.mounth

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
  Year(si.InvoiceDate) as SALE_YEAR 
, MONTH(si.InvoiceDate) as SALE_MONTH
, sl.Description
, sum (sl.Quantity * sl.UnitPrice) as sum_sales    
, MIN (si.InvoiceDate) [FIRST_SALE]
, sum (sl.Quantity) as [QTY]
from
Sales.Invoices si (nolock)
join Sales.InvoiceLines sl (nolock) on si.InvoiceID = sl.InvoiceID

group by Year(si.InvoiceDate) , MONTH(si.InvoiceDate) , sl.Description
having sum (sl.Quantity ) < 50


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
