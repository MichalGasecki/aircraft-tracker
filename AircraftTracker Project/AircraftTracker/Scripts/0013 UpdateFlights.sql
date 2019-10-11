CREATE PROCEDURE dbo.UpdateFlights AS

UPDATE Flight
   SET DepartureScheduled = (SELECT DepartureScheduled FROM dbo.GetFlightTimes(URL)),
       DepartureActual = (SELECT DepartureActual FROM dbo.GetFlightTimes(URL)),
       ArrivalScheduled = (SELECT ArrivalScheduled FROM dbo.GetFlightTimes(URL)),
       ArrivalActual = (SELECT ArrivalActual FROM dbo.GetFlightTimes(URL)),
       Status = (SELECT Status FROM dbo.GetFlightTimes(URL))
 WHERE Date BETWEEN CAST(DATEADD(DAY, -1, GETDATE()) AS DATE) AND CAST(GETDATE() AS DATE) AND
      (DepartureScheduled IS NULL OR
       DepartureActual IS NULL OR
	   ArrivalScheduled IS NULL OR
	   ArrivalActual IS NULL)