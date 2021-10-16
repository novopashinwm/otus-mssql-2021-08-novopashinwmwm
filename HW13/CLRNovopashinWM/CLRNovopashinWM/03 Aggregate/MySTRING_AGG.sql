use WideWorldImporters
/*DROP ASSEMBLY IF EXISTS DemoNovopashinWM
GO
CREATE ASSEMBLY DemoNovopashinWM
FROM 'D:\projects\OTUS\SQL\otus-mssql-2021-08-novopashinwmwm\HW13\CLRNovopashinWM\CLRNovopashinWM\bin\Debug\CLRNovopashinWM.dll'
WITH PERMISSION_SET = SAFE; */
go
CREATE AGGREGATE MySTRING_AGG (@input nvarchar(200), @delimiter nvarchar(10)) RETURNS nvarchar(max)  
EXTERNAL NAME DemoNovopashinWM.[CLRNovopashinWM.MySTRING_AGG];
go
