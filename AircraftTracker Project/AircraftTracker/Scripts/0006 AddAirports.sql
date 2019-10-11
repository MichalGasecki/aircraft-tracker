CREATE PROCEDURE dbo.AddAirports AS

DECLARE @Country NVARCHAR(200)

DECLARE countries CURSOR FOR SELECT URL FROM Country

OPEN countries;
FETCH NEXT FROM countries INTO @Country
WHILE @@FETCH_STATUS=0
BEGIN

EXEC	dbo.AddAirportsFromCountry
		@Country = @Country

PRINT @Country

FETCH NEXT FROM countries INTO @Country
END
CLOSE countries
DEALLOCATE countries