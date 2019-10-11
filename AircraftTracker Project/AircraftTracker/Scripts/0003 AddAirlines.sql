CREATE PROCEDURE dbo.AddAirlines AS

DECLARE @HTML NVARCHAR(MAX)
SET @HTML = dbo.Pobierz('https://www.airportia.com/airlines/')
SET @HTML = dbo.Wytnij(@HTML, '<div class="textlist-body">(.|\n)*?</div>')

DECLARE @XML XML = CAST(@HTML AS XML);

WITH dane AS
(
SELECT a.b.value('@title','NVARCHAR(100)') AS Name,
       a.b.value('@href','NVARCHAR(100)') AS URL
FROM @xml.nodes ('div/a') AS a(b)
)
INSERT INTO Airline
SELECT Name,
	   'https://www.airportia.com' + URL AS URL
FROM dane
WHERE Name NOT IN (SELECT Name FROM Airline)