CREATE PROCEDURE dbo.AddFlightsFromAirport (@Airport NVARCHAR(200), @Date DATE) AS

--DECLARE @Airport NVARCHAR(200) = 'https://www.airportia.com/poland/warsaw-chopin-airport/'
--DECLARE @Date DATE = '20190901'

WHILE @Date <= GETDATE()
BEGIN

EXEC	dbo.AddFlights
		@Airport = @Airport,
		@Date = @Date

PRINT @Date

SET @Date = DATEADD(DAY, 1, @Date)

END