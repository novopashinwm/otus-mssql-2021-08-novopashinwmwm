/*

Для всех заданий, где возможно, сделайте два варианта запросов:

    через вложенный запрос
    через WITH (для производных таблиц)

Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. Продажи смотреть в таблице Sales.Invoices.
*/
use WideWorldImporters
go

select ap.PersonID , ap.FullName
from Application.People ap
where ap.IsSalesperson = 1
and not exists (select * from Sales.Invoices si where  si.InvoiceDate ='20150704' and si.SalespersonPersonID = ap.PersonID)
go
with InvoiceCTE as (select si.InvoiceDate, si.SalespersonPersonID from Sales.Invoices si where  si.InvoiceDate ='20150704')
select ap.PersonID , ap.FullName
from Application.People ap
where ap.IsSalesperson = 1
and not ap.PersonID in (select SalespersonPersonID from InvoiceCTE)
go

/*Выберите товары с минимальной ценой (подзапросом). 
Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.*/
select si.StockItemID, si.StockItemName, si.UnitPrice 
from 
Warehouse.StockItems as si
where
si.UnitPrice = (select min (UnitPrice) from Warehouse.StockItems)
go
with MinPriceCTE as (select min (UnitPrice) as MinPrice from Warehouse.StockItems)
select si.StockItemID, si.StockItemName, si.UnitPrice 
from 
Warehouse.StockItems as si
join MinPriceCTE as mpc on si.UnitPrice = mpc.MinPrice
go

/*Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE).*/

select cs.CustomerID, cs.CustomerName
from 
Sales.Customers cs
where
cs.CustomerID in (select top 5 st.CustomerID from Sales.CustomerTransactions st 
order by TransactionAmount desc)
go

with MaxTransactionCTE as (select top 5 st.CustomerID from Sales.CustomerTransactions st 
order by TransactionAmount desc)
select distinct cs.CustomerID, cs.CustomerName
from 
Sales.Customers cs
join MaxTransactionCTE mt on cs.CustomerID = mt.CustomerID
go
/*Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, 
а также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID).
---------------------------------------------------------------------------------

У меня вопрос - не подскажите какие таблички я должен смотреть - по продажам 
или же по поставке товара? Просто не совсем понял как связаны Purchasing.PurchaseOrderLines
c Sales.Invoices
*/

select ap.CityID, ap.CityName
from Application.Cities ap

--select distinct top 3   StockItemID from Purchasing.PurchaseOrderLines order by ExpectedUnitPricePerOuter desc;

--select * from Sales.Invoices

go
with  MaxExpensiveCTE as (select top 3  UnitPrice from Sales.OrderLines
group by UnitPrice
order by UnitPrice desc ),
 OrdersLineCTE as (select sor.OrderID from Sales.OrderLines sor where sor.UnitPrice = MaxExpensiveCTE.UnitPrice)
 ,OrdersCTE as (select ord.CustomerID from Sales.Orders as ord where ord.OrderID = OrdersLineCTE.OrderID )
 , CustomersCTE as (select cust.DeliveryCityID from Sales.Customers cust where cust.CustomerID = OrdersCTE.CustomerID)
 select ap.CityID, ap.CityName from 
 Application.Cities ap
 join CustomersCTE cs on ap.CityID  = cs.DeliveryCityID 

--select * from MaxExpensive

/*select * from sysobjects where id in (
select id from syscolumns where name like '%CityID%')*/