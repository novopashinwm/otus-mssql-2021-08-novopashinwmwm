create or alter procedure spAddSaldo (
     @BookID bigint
   , @SaldoBegin int	  
   , @QtyIn int
   , @QtyOut int

)
as
begin
    insert into BooksSaldo 
	     values (GETDATE(), @BookID, @SaldoBegin, @QtyIn, @QtyOut, @SaldoBegin + @QtyIn - @QtyOut) 
end 
go

create or alter procedure spAddDoc
(
  @UserID bigint
)
as
begin
    insert into Docs values (@UserID, GetDate(), null, null)
	select SCOPE_IDENTITY() as ID
end
go
create or alter procedure spAddDocInBook
(
     @DocID bigint
   , @CupboardID bigint
   , @BookID bigint
   , @Qty int
)
as
begin

	insert into DocsIn values (@DocID, @CupboardID, @BookID, @Qty)
	declare @Saldo int = Isnull((select top 1 SaldoEnd from BooksSaldo where BookID = @BookID order by BookSaldoID desc),0)
	exec spAddSaldo @BookID, @Saldo, @Qty, 0
end
go

create or alter procedure spAddDocOutBook
(
     @DocID bigint
   , @BookID bigint
   , @Qty int
   , @ReaderID bigint
   , @DateReturn datetime2
)
as
begin

	insert into DocsOut values (@DocID, @BookID, @Qty, @ReaderID, @DateReturn)
	declare @Saldo int = Isnull((select top 1 SaldoEnd from BooksSaldo where BookID = @BookID order by BookSaldoID desc),0)
	exec spAddSaldo @BookID, @Saldo, 0, @Qty
end
go
exec spAddDoc @UserID=1
go
exec spAddDocInBook @DocID= 1, @CupboardID=2, @BookID= 4, @Qty= 7
go
exec spAddDoc @UserID=2
go
exec spAddDocOutBook @DocID= 2, @BookID= 4, @Qty= 1, @ReaderID =2, @DateReturn ='2021-12-21'
go