use WideWorldImporters;
go
CREATE TYPE dbo.RuPassport   
EXTERNAL NAME DemoNovopashinWM.[CLRNovopashinWM.RuPassport];
go
DECLARE @passport RuPassport
SET @passport = '5105495930'
SELECT 
	@passport as [Binary], 
	@passport.Number as [Number],
	@passport.ToString() as [ToString]
go
-- NULL
DECLARE @passport RuPassport
SELECT 
	@passport as [Binary],
	@passport.Number as [Number],
	@passport.ToString() as [ToString]
go
-- Валидация (вызывается Parse())
DECLARE @passport RuPassport
SET @passport = '123'
GO

-- Можно присвоить значение и через свойство
DECLARE @passport RuPassport
SET @passport = '1111111111'
SET @passport.Number = '5105495930'
SELECT 
	@passport as [Binary], 
	@passport.Number as [Number],
	@passport.ToString() as [ToString]
GO

-- Можно присвоить значение и через свойство
DECLARE @passport RuPassport
SET @passport = '1111111111'
SET @passport.Number = '5105495930'
SELECT 
	@passport as [Binary], 
	@passport.ToString() as [ToString], 
	@passport.Number as [Number]
GO

-- Пример использования как типа колонки
DROP TABLE IF EXISTS Employees;
GO

CREATE TABLE Employees
(
	Name nvarchar(20),
	Passport RuPassport
)
GO

INSERT INTO Employees VALUES('empl_1', '9001234567')
GO

SELECT * FROM Employees e
GO

-- ошибка (значение не валидное)
INSERT INTO Employees VALUES('empl_2', '1234567')
GO

SELECT 
 e.Name, 
 e.Passport, 
 e.Passport.ToString() as Passport_ToString,
 e.Passport.Number as Number
FROM Employees e
GO

-- Можем применять в WHERE
SELECT 
 e.Name, 
 e.Passport, 
 e.Passport.ToString() as Passport_ToString,
 e.Passport.Number as Number
FROM Employees e
WHERE e.Passport = '9001234567'
GO

-- А так будет работать?
INSERT INTO Employees 
VALUES('empl_3', '90 01 234567')

DROP TABLE Employees
GO
