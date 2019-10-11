CREATE PROCEDURE dbo.AddFlights (@Airport NVARCHAR(200), @Date DATE) AS

--DECLARE @Airport NVARCHAR(200) = 'https://www.airportia.com/poland/warsaw-chopin-airport/'
--DECLARE @Date DATE = '20190917'

DECLARE @FlightsTable TABLE (
	Flight NVARCHAR(200),
	Codeshare BIT,
	SourceID NVARCHAR(3),
	DestinationID NVARCHAR(3),
	AirlineID INT,
	Aircraft NVARCHAR(200),
	Date DATE,
	DepartureScheduled DATETIME,
	DepartureActual DATETIME,
	ArrivalScheduled DATETIME,
	ArrivalActual DATETIME,
	Status NVARCHAR(200),
	URL NVARCHAR(200)
)

DECLARE @HTML NVARCHAR(MAX)
SET @HTML = dbo.Pobierz(@Airport + 'departures/' + REPLACE(CAST(@Date AS NVARCHAR(10)), '-', '') + '/0000/2359/')
SET @HTML = dbo.Wytnij(@HTML, '<table class="flightsTable flightsTable--airportDepartures">(.|\n)*?</table>')
SET @HTML = dbo.Podstaw(@HTML, '<span class="hidden-xs">(.|\n)*?</span>', '')
--SET @HTML = dbo.Podstaw(@HTML, '<tr class="flightsTable-childFlight">(.|\n)*?</tr>', '')

DECLARE @XML XML = CAST(@HTML AS XML);

WITH dane AS
(
SELECT a.b.value('td[1]/a[1]','NVARCHAR(100)') AS Flight,
       a.b.value('@class','NVARCHAR(1000)') AS Codeshare,
       a.b.value('td[2]/a[1]','NVARCHAR(100)') AS Destination,
       a.b.value('td[3]/a[1]/@href','NVARCHAR(100)') AS Airline,
       a.b.value('td[4]','NVARCHAR(100)') AS Scheduled,
       a.b.value('td[5]','NVARCHAR(100)') AS Departure,
       a.b.value('td[6]','NVARCHAR(100)') AS Status,
       a.b.value('td[7]/a[1]/@href','NVARCHAR(1000)') AS URL
FROM @xml.nodes ('table/tr') AS a(b)
)

INSERT INTO @FlightsTable
SELECT Flight,
       CASE
	       WHEN Codeshare = 'flightsTable-childFlight' THEN 1
		   ELSE 0
	   END AS Codeshare,
       (SELECT AirportID FROM Airport WHERE URL = @Airport) AS SourceID,
       TRIM(Destination) AS DestinationID,
	   (SELECT AirlineID FROM Airline WHERE URL = 'https://www.airportia.com' + Airline) AS AirlineID,
	   CASE
	       WHEN DATEDIFF(DAY, @Date, GETDATE()) <= 7 THEN dbo.GetAircraft(Flight,
		                                                                  @Date,
																		  (SELECT AirportID FROM Airport WHERE URL = @Airport))
		   ELSE NULL
	   END AS Aircraft,
	   @Date AS Date,
	   (SELECT DepartureScheduled FROM dbo.GetFlightTimes('https://www.airportia.com' + URL)) AS DepartureScheduled,
	   (SELECT DepartureActual FROM dbo.GetFlightTimes('https://www.airportia.com' + URL)) AS DepartureActual,
	   (SELECT ArrivalScheduled FROM dbo.GetFlightTimes('https://www.airportia.com' + URL)) AS ArrivalScheduled,
	   (SELECT ArrivalActual FROM dbo.GetFlightTimes('https://www.airportia.com' + URL)) AS ArrivalActual,
	   Status,
	   'https://www.airportia.com' + URL AS URL
FROM dane
WHERE Flight IS NOT NULL AND Flight NOT LIKE '%Flight?%'
      AND Flight NOT IN (SELECT Flight FROM Flight WHERE Date = @Date)

DECLARE @Aircraft NVARCHAR(200)

DECLARE aircrafts CURSOR FOR SELECT DISTINCT Aircraft
                             FROM @FlightsTable
							 WHERE DATEDIFF(DAY, @Date, GETDATE()) <= 7 AND Aircraft IS NOT NULL

OPEN aircrafts;
FETCH NEXT FROM aircrafts INTO @Aircraft
WHILE @@FETCH_STATUS=0
BEGIN

EXEC	dbo.AddAircraft
		@Name = @Aircraft

FETCH NEXT FROM aircrafts INTO @Aircraft
END
CLOSE aircrafts
DEALLOCATE aircrafts

INSERT INTO Flight
SELECT Flight,
       Codeshare,
	   SourceID,
	   DestinationID,
	   AirlineID,
	   (SELECT AircraftID FROM Aircraft WHERE Name = Aircraft) AS AircraftID,
	   Date,
	   DepartureScheduled,
	   DepartureActual,
	   ArrivalScheduled,
	   ArrivalActual,
	   Status,
	   URL
FROM @FlightsTable