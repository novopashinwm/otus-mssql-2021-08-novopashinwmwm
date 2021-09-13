/*

��� ���� �������, ��� ��������, �������� ��� �������� ��������:

    ����� ��������� ������
    ����� WITH (��� ����������� ������)

�������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), 
� �� ������� �� ����� ������� 04 ���� 2015 ����. 
������� �� ���������� � ��� ������ ���. ������� �������� � ������� Sales.Invoices.
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

/*�������� ������ � ����������� ����� (�����������). 
�������� ��� �������� ����������. 
�������: �� ������, ������������ ������, ����.*/
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

/*�������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� 
�� Sales.CustomerTransactions. 
����������� ��������� �������� (� ��� ����� � CTE).*/

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
/*�������� ������ (�� � ��������), � ������� ���� ���������� ������, 
�������� � ������ ����� ������� �������, 
� ����� ��� ����������, ������� ����������� �������� ������� (PackedByPersonID).
---------------------------------------------------------------------------------

� ���� ������ - �� ���������� ����� �������� � ������ �������� - �� �������� 
��� �� �� �������� ������? ������ �� ������ ����� ��� ������� Purchasing.PurchaseOrderLines
c Sales.Invoices
*/

select ap.CityID, ap.CityName
from Application.Cities ap

--select distinct top 3   StockItemID from Purchasing.PurchaseOrderLines order by ExpectedUnitPricePerOuter desc;

--select * from Sales.Invoices