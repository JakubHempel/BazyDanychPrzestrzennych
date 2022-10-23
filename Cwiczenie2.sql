-- 4. Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty)
-- położonych w odległości mniejszej niż 1000 m od głównych rzek. Budynki spełniające to
-- kryterium zapisz do osobnej tabeli tableB.
CREATE TABLE tableB AS(
	SELECT COUNT(DISTINCT p.gid) AS BuildingsCount
	FROM popp AS p, majrivers AS r
	WHERE ST_DWithin(p.geom, r.geom, 1000) AND p.f_codedesc = 'Building'
);

SELECT * FROM tableB
--DROP TABLE tableB

-- 5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
-- geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.
-- a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.
--SELECT * FROM airports;

CREATE TABLE airportsNew AS (
	SELECT name, geom, elev
	FROM airports
);

SELECT east.name, ST_AsText(east.geom) AS EasternAirport, west.name, ST_AsText(west.geom) AS WesternAirport
FROM airportsNew AS east, airportsNew AS west
WHERE (ST_X(east.geom) = (SELECT MAX(ST_X(geom)) FROM airportsNew)) 
AND (ST_X(west.geom) = (SELECT MIN(ST_X(geom)) FROM airportsNew));

-- b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
-- środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB.
-- Wysokość n.p.m. przyjmij dowolną.
INSERT INTO airportsNew VALUES
('airportB', (SELECT ST_Centroid(
				     		     ST_ShortestLine(
									            (SELECT geom FROM airportsNew WHERE name = 'ANETTE ISLAND'), 
									            (SELECT geom FROM airportsNew WHERE name = 'ATKA')))), 85);

SELECT * FROM airportsNew WHERE name ='ANNETTE ISLAND' OR name ='ATKA' OR name='airportB';
--DELETE FROM airportsNew WHERE name ='airportB';

-- 6) Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
-- linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”
SELECT ST_Area(ST_Buffer(ST_ShortestLine(l.geom, a.geom), 1000)) AS Area
FROM lakes AS l, airportsNew AS a
WHERE l.names = 'Iliamna Lake' AND a.name = 'AMBLER';

-- 7) Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
-- poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps)
SELECT tr.vegdesc AS Species, (SUM(tu.area_km2)+SUM(s.areakm2)) AS Area
FROM tundra AS tu, trees AS tr, swamp AS s 
WHERE tu.area_km2 IN (SELECT tu.area_km2 
					  FROM tundra AS tu, trees AS tr 
					  WHERE ST_Contains(tr.geom, tu.geom) = 'true') 
AND s.areakm2 IN (SELECT s.areakm2 
			      FROM swamp AS s, trees AS tr
				  WHERE ST_Contains(tr.geom, s.geom) = 'true') 
GROUP BY (tr.vegdesc);
