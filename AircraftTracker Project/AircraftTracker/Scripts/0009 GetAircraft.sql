CREATE FUNCTION dbo.GetAircraft (@Flight NVARCHAR(200), @Date DATE, @SourceID NVARCHAR(200))
RETURNS NVARCHAR(200)
AS
BEGIN

	--DECLARE @Flight NVARCHAR(200) = 'W61567'
 --   DECLARE @Date DATE = '20190913'
	--DECLARE @SourceID NVARCHAR(200) = 'WAW'

	DECLARE @AircraftID NVARCHAR(200)

	DECLARE @HTML NVARCHAR(MAX)

	SET @HTML = dbo.Pobierz('https://www.flightradar24.com/data/flights/' + @Flight)
	SET @HTML = dbo.Wytnij(@HTML, '<tbody>(.|\n)*?</tbody>')
	SET @HTML = dbo.Podstaw(@HTML, '&mdash;', '')
	SET @HTML = dbo.Podstaw(@HTML, '&nbsp;', ' ')
	SET @HTML = dbo.Podstaw(@HTML, '<a class(.|\n)*?</a>', ' ')

	DECLARE @XML XML = CAST(@HTML AS XML);

	WITH dane AS
	(
	SELECT a.b.value('td[1]/div[1]/div[3]/p[1]/span[1]/a[1]','NVARCHAR(100)') AS SourceID,
	       a.b.value('td[1]/div[1]/div[1]/div[2]','NVARCHAR(100)') AS Date,
		   a.b.value('td[6]','NVARCHAR(100)') AS Name
	FROM @XML.nodes ('tbody/tr') AS a(b)
	)
	SELECT @AircraftID = (SELECT DISTINCT TRIM(Name)
	                      FROM dane
						  WHERE CAST(TRIM(Date) AS Date) = @Date AND dbo.Wytnij(SourceID, '[A-Z]{3}') = @SourceID)

	RETURN @AircraftID

END