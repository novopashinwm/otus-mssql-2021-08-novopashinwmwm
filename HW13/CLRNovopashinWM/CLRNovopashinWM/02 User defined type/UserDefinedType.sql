USE WideWorldImporters
GO
-- У меня не получилось зарегить тип - может что-то не то делаю
CREATE TYPE dbo.RuPassport   
EXTERNAL NAME [DemoNovopashinWM].[RuPassport]; 
go
DECLARE @passport RuPassport
SET @passport = '0700301203'
SELECT 
	@passport as [Binary], 
	@passport.ToString() as [ToString]