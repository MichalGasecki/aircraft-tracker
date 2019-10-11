EXEC dbo.CreateTables

DECLARE @result INT

-- IMPORT COUNTRIES FROM XML

DECLARE @XMLCountry XML

EXEC master.dbo.xp_fileexist 'C:\Countries.xml', @result OUTPUT

IF @result = 1
SELECT @XMLCountry = Country
FROM OPENROWSET (BULK 'C:\Countries.xml', SINGLE_BLOB) AS Countries(Country)

INSERT INTO Country
SELECT Countries.Country.value('Name[1]','NVARCHAR(100)') AS Name,
       Countries.Country.value('URL[1]','NVARCHAR(100)') AS URL
FROM @XMLCountry.nodes ('Country') AS Countries(Country)

-- IMPORT AIRPORTS FROM XML

DECLARE @XMLAirport XML

EXEC master.dbo.xp_fileexist 'C:\Airports.xml', @result OUTPUT

IF @result = 1
SELECT @XMLAirport = Airport
FROM OPENROWSET (BULK 'C:\Airports.xml', SINGLE_BLOB) AS Airports(Airport);

WITH data AS
(
	SELECT Airports.Airport.value('AirportID[1]','NVARCHAR(200)') AS AirportID,
		   Airports.Airport.value('Country[1]','NVARCHAR(200)') AS Country,
		   Airports.Airport.value('Name[1]','NVARCHAR(200)') AS Name,
		   Airports.Airport.value('Lat[1]','NVARCHAR(100)') AS Lat,
		   Airports.Airport.value('Long[1]','NVARCHAR(100)') AS Long,
		   Airports.Airport.value('URL[1]','NVARCHAR(200)') AS URL
	FROM @XMLAirport.nodes ('Airport') AS Airports(Airport)
)
INSERT INTO Airport
SELECT AirportID
      ,(SELECT CountryID FROM Country WHERE Name = data.Country) AS CountryID
	  ,Name
	  ,IIF(Lat IS NOT NULL AND Long IS NOT NULL, GEOGRAPHY::Point(Lat, Long, 4326), NULL) AS Location
	  ,URL
FROM data

-- IMPORT AIRLINES FROM XML

DECLARE @XMLAirline XML

EXEC master.dbo.xp_fileexist 'C:\Airlines.xml', @result OUTPUT

IF @result = 1
SELECT @XMLAirline = Airline
FROM OPENROWSET (BULK 'C:\Airlines.xml', SINGLE_BLOB) AS Airlines(Airline)

INSERT INTO Airline
SELECT Airlines.Airline.value('Name[1]','NVARCHAR(100)') AS Name,
       Airlines.Airline.value('URL[1]','NVARCHAR(100)') AS URL
FROM @XMLAirline.nodes ('Airline') AS Airlines(Airline)