CREATE FUNCTION dbo.GetAirportLocation (@Airport NVARCHAR(200))
RETURNS GEOGRAPHY
AS
BEGIN

--DECLARE @Airport NVARCHAR(200) = 'https://www.airportia.com/brazil/guarulhos-_-governador-andr%c3%a9-franco-montoro-international-airport/'

DECLARE @AirportLocation GEOGRAPHY

DECLARE @HTML NVARCHAR(MAX)
SET @HTML = dbo.Pobierz(@Airport)
SET @HTML = dbo.Wytnij(@HTML, '<div itemprop="geo" itemscope itemtype="http://schema.org/GeoCoordinates">(.|\n)*?</div>')
SET @HTML = dbo.Podstaw(@HTML, ' itemprop="geo"(.+)>', '>')
SET @HTML = dbo.Podstaw(@HTML, '">', '"></meta>')

DECLARE @XML XML = CAST(@HTML AS XML);

WITH dane AS
(
	SELECT a.b.value('meta[contains(@itemprop, "latitude")][1]/@content','NVARCHAR(100)') AS Latitude,
			a.b.value('meta[contains(@itemprop, "longitude")][1]/@content','NVARCHAR(100)') AS Longitude
	FROM @XML.nodes ('div') AS a(b)
)
SELECT @AirportLocation = GEOGRAPHY::Point(Latitude, Longitude, 4326) FROM dane

IF @Airport = 'https://www.airportia.com/united-states/rock-hill/york-co./bryant-field-airport/'
SELECT @AirportLocation = GEOGRAPHY::Point('34.9878', '-81.0572', 4326)

IF @Airport = 'https://www.airportia.com/canada/c-j.h.l./'
SELECT @AirportLocation = GEOGRAPHY::Point('46.9022', '-71.5022', 4326)

RETURN @AirportLocation

END