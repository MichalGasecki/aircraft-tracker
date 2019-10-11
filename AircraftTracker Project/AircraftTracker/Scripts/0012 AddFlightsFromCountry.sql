CREATE PROCEDURE dbo.AddFlightsFromCountry (@CountryID NVARCHAR(200)) AS

--DECLARE @CountryID INT = 170

DECLARE @Date DATE = (SELECT GETDATE())

DECLARE @Airport NVARCHAR(200)

DECLARE airports CURSOR FOR SELECT URL FROM Airport WHERE CountryID = @CountryID

OPEN airports;
FETCH NEXT FROM airports INTO @Airport
WHILE @@FETCH_STATUS=0
BEGIN

EXEC	dbo.AddFlightsFromAirport
		@Airport = @Airport,
		@Date = @Date

--PRINT @Airport

FETCH NEXT FROM airports INTO @Airport
END
CLOSE airports
DEALLOCATE airports