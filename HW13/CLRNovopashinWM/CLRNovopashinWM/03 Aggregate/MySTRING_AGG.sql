use WideWorldImporters
go
CREATE AGGREGATE MySTRING_AGG (@input nvarchar(200), @delimiter nvarchar(10)) RETURNS nvarchar(max)  
EXTERNAL NAME DemoNovopashinWM.[CLRNovopashinWM.MySTRING_AGG];
go
declare @table table (n1 varchar(255))
insert @table values ('first'),('second'),('third'),('four')
select * from @table

select STRING_AGG(n1,',') from @table
select dbo.MySTRING_AGG(n1,',') from @table
go