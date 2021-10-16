use WideWorldImporters

-- Чистим от предыдущих экспериментов
DROP FUNCTION IF EXISTS dbo.fn_Luhn
GO
DROP PROCEDURE IF EXISTS dbo.fn_MyLike
GO
DROP ASSEMBLY IF EXISTS DemoNovopashinWM
GO

-- Включаем CLR
exec sp_configure 'show advanced options', 1;
GO
reconfigure;
GO

exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0 
GO

-- clr strict security 
-- 1 (Enabled): заставляет Database Engine игнорировать сведения PERMISSION_SET о сборках 
-- и всегда интерпретировать их как UNSAFE. По умолчанию, начиная с SQL Server 2017.

reconfigure;
GO

-- Для возможности создания сборок с EXTERNAL_ACCESS или UNSAFE
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 

-- Подключаем dll 
-- Измените путь к файлу!
CREATE ASSEMBLY DemoNovopashinWM
FROM 'D:\projects\OTUS\SQL\otus-mssql-2021-08-novopashinwmwm\HW13\CLRNovopashinWM\CLRNovopashinWM\bin\Debug\CLRNovopashinWM.dll'
WITH PERMISSION_SET = SAFE; 

SELECT * FROM sys.assemblies
go
CREATE FUNCTION dbo.fn_Luhn(@Name nvarchar(20))  
RETURNS bit
AS EXTERNAL NAME [DemoNovopashinWM].[CLRNovopashinWM.DemoFunctionCLR].Luhn;
GO 
CREATE FUNCTION dbo.fn_MyLike(@input nvarchar(255), @pattern nvarchar(255))  
RETURNS bit
AS EXTERNAL NAME [DemoNovopashinWM].[CLRNovopashinWM.DemoFunctionCLR].MyLike ;
GO 
--Можете ввести номер своей карты 
select dbo.fn_Luhn ('5559493694071227') as Right_Card
--Не правильная карта
select dbo.fn_Luhn ('5559493694071220') as WRONG_CARD
go
-- Нашел в чем была ошибка - в функции fn_MyLike я в параметре @input указывал nvarchar - а это один символ
-- а надо было поставить количество символов
select dbo.fn_MyLike('0700','^\d+$')
select dbo.fn_MyLike(' 0700', '^\d+$')
--Проверка, что это российский паспорт
select dbo.fn_MyLike('0700 123456','^\d{4} \d{6}$')
select dbo.fn_MyLike('07 00 123456','^\d{4} \d{6}$')
go