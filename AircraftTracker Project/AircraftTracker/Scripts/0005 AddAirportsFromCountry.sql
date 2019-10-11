CREATE PROCEDURE dbo.AddAirportsFromCountry (@Country NVARCHAR(200)) AS

--DECLARE @Country NVARCHAR(100) = 'https://www.airportia.com/poland/'

DECLARE @HTML NVARCHAR(MAX)
SET @HTML = dbo.Pobierz(@Country)
SET @HTML = dbo.Wytnij(@HTML, '<div class="textlist">(.|\n)*?</div>')
SET @HTML = dbo.Podstaw(@HTML, '<div class="textlist">', '')
SET @HTML = dbo.Podstaw(@HTML, 'title="[^"]+"', '')
SET @HTML = dbo.Podstaw(@HTML, '&nbsp', ' ')
SET @HTML = dbo.Podstaw(@HTML, '&', '&amp;')

DECLARE @XML XML = CAST(@HTML AS XML);

WITH dane AS
(
SELECT a.b.value('.','NVARCHAR(100)') AS AirportID,
       a.b.value('.','NVARCHAR(100)') AS Name,
       a.b.value('@href','NVARCHAR(100)') AS URL
FROM @xml.nodes ('div/a') AS a(b)
)
INSERT INTO Airport
SELECT dbo.Wytnij(dbo.Wytnij(AirportID, '\([A-Z]{3}\)'), '\w{3}') AS AirportID,
       (SELECT CountryID FROM Country WHERE URL = @Country) AS CountryID,
	   dbo.Podstaw(REPLACE(Name, '  ', ' '), ' \([A-Z]{3}\)', '') AS Name,
	   dbo.GetAirportLocation('https://www.airportia.com' + URL) AS Location,
	   'https://www.airportia.com' + URL AS URL
FROM dane
WHERE dbo.Wytnij(dbo.Wytnij(AirportID, '\([A-Z]{3}\)'), '\w{3}') NOT IN (SELECT AirportID FROM Airport)