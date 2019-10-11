CREATE FUNCTION dbo.GetFlightTimes (@Flight NVARCHAR(200))
RETURNS @FlightTimesTABLE TABLE(DepartureScheduled DATETIME,
                                DepartureActual DATETIME,
								ArrivalScheduled DATETIME,
								ArrivalActual DATETIME,
								Status NVARCHAR(200))
AS
BEGIN

	--DECLARE @Flight NVARCHAR(200) = 'https://www.airportia.com/flights/w61751/gda%c5%84sk/turku/2019-05-27/'

	DECLARE @HTML NVARCHAR(MAX)
	DECLARE @Status NVARCHAR(200)

	SET @HTML = dbo.Pobierz(@Flight)
	SET @Status = dbo.Wytnij(@HTML, '<div class="flightInfo-status(.|\n)*?</div>')
	SET @HTML = dbo.Wytnij(@HTML, '<div style="display: none;">(.|\n)*?</div>')

	DECLARE @XML XML = CAST(@HTML AS XML);

	WITH dane AS
	(
	SELECT a.b.value('ul[1]/li[1]','NVARCHAR(100)') AS DepartureScheduled,
		   a.b.value('ul[1]/li[2]','NVARCHAR(100)') AS DepartureEsitmated,
		   a.b.value('ul[1]/li[4]','NVARCHAR(100)') AS DepartureActual,
		   a.b.value('ul[1]/li[5]','NVARCHAR(100)') AS DepartureActualRunway,
		   a.b.value('ul[2]/li[1]','NVARCHAR(100)') AS ArrivalScheduled,
		   a.b.value('ul[2]/li[2]','NVARCHAR(100)') AS ArrivalEsitmated,
		   a.b.value('ul[2]/li[4]','NVARCHAR(100)') AS ArrivalActual,
		   a.b.value('ul[2]/li[5]','NVARCHAR(100)') AS ArrivalActualRunway
	FROM @XML.nodes ('div') AS a(b)
	), czas AS
	(
	SELECT dbo.Podstaw(dbo.Wytnij(DepartureScheduled, ': .*'), ': (N/A)*', '') AS DepartureScheduled
		  ,dbo.Podstaw(dbo.Wytnij(DepartureEsitmated, ': .*'), ': (N/A)*', '') AS DepartureEsitmated
		  ,dbo.Podstaw(dbo.Wytnij(DepartureActual, ': .*'), ': (N/A)*', '') AS DepartureActual
		  ,dbo.Podstaw(dbo.Wytnij(DepartureActualRunway, ': .*'), ': (N/A)*', '') AS DepartureActualRunway
		  ,dbo.Podstaw(dbo.Wytnij(ArrivalScheduled, ': .*'), ': (N/A)*', '') AS ArrivalScheduled
		  ,dbo.Podstaw(dbo.Wytnij(ArrivalEsitmated, ': .*'), ': (N/A)*', '') AS ArrivalEsitmated
		  ,dbo.Podstaw(dbo.Wytnij(ArrivalActual, ': .*'), ': (N/A)*', '') AS ArrivalActual
		  ,dbo.Podstaw(dbo.Wytnij(ArrivalActualRunway, ': .*'), ': (N/A)*', '') AS ArrivalActualRunway
	FROM dane
	), gotowe AS
	(
	SELECT CASE
			   WHEN LEN(DepartureScheduled) = 0 THEN NULL
			   ELSE CAST(DepartureScheduled AS DATETIME)
		   END AS DepartureScheduled,
		   CASE
			   WHEN LEN(DepartureActual) > 0 THEN CAST(DepartureActual AS DATETIME)
			   WHEN LEN(DepartureActual) = 0 AND LEN(DepartureActualRunway) > 0 THEN CAST(DepartureActualRunway AS DATETIME)
			   WHEN LEN(DepartureActual) = 0 AND LEN(DepartureEsitmated) > 0 THEN CAST(DepartureEsitmated AS DATETIME)
			   ELSE NULL
		   END AS DepartureActual,
		   CASE
			   WHEN LEN(ArrivalScheduled) = 0 THEN NULL
			   ELSE CAST(ArrivalScheduled AS DATETIME)
		   END AS ArrivalScheduled,
		   CASE
			   WHEN LEN(ArrivalActual) > 0 THEN CAST(ArrivalActual AS DATETIME)
			   WHEN LEN(ArrivalActual) = 0 AND LEN(ArrivalActualRunway) > 0 THEN CAST(ArrivalActualRunway AS DATETIME)
			   WHEN LEN(ArrivalActual) = 0 AND LEN(ArrivalEsitmated) > 0 THEN CAST(ArrivalEsitmated AS DATETIME)
			   ELSE NULL
		   END AS ArrivalActual
	FROM czas
	)	
	INSERT INTO @FlightTimesTABLE
	SELECT DepartureScheduled,
	       IIF(DepartureActual <= GETDATE(), DepartureActual, NULL) AS DepartureActual,
		   ArrivalScheduled,
		   IIF(ArrivalActual <= GETDATE(), ArrivalActual, NULL) AS ArrivalActual,
		   dbo.Podstaw(dbo.Podstaw(
		               dbo.Podstaw(
					   dbo.Wytnij(@Status, '>(.|\n)*?<')
					                     , '>', '')
										 , '<', '')
										 , '&gt;', '>') AS Status
	FROM gotowe
	RETURN

END