CREATE PROCEDURE dbo.AddCountries AS

DECLARE @HTML NVARCHAR(MAX)
SET @HTML = dbo.Pobierz('https://www.airportia.com/airports/')
SET @HTML = dbo.Wytnij(@HTML, '<div class="textlist">(.|\n)*?</div>')
SET @HTML = dbo.Podstaw(@HTML, '<div class="textlist">', '')

DECLARE @XML XML = CAST(@HTML AS XML);

WITH dane AS
(
SELECT a.b.value('@title','NVARCHAR(100)') AS Country,
       a.b.value('@href','NVARCHAR(100)') AS URL
FROM @xml.nodes ('div/a') AS a(b)
)
INSERT INTO Country
SELECT Country,
	   'https://www.airportia.com' + URL AS URL
FROM dane
WHERE Country NOT IN (SELECT Country FROM Country)