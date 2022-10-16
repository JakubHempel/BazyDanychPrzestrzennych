-- Rozszerzamy o funkcjonalnosc postgisa
CREATE EXTENSION postgis;

-- Tworzenie tabel 
CREATE TABLE budynki(
	id INT NOT NULL PRIMARY KEY,
	geometria GEOMETRY,
	nazwa VARCHAR(20),
	wysokosc INT
);

CREATE TABLE drogi(
	id INT NOT NULL PRIMARY KEY,
	geometria GEOMETRY,
	nazwa VARCHAR(10)
);

CREATE TABLE pktinfo(
	id INT NOT NULL PRIMARY KEY,
	geometria GEOMETRY,
	nazwa CHAR(1),
	liczprac INT
);

-- Wprowadzanie danych do tabel
INSERT INTO budynki VALUES
(1, ST_GeomFromText('POLYGON((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))', 0), 'BuildingA', 15),
(2, ST_GeomFromText('POLYGON((4 5, 6 5, 6 7, 4 7, 4 5))', 0) , 'BuildingB', 20),
(3, ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))', 0), 'BuildingC', 50),
(4, ST_GeomFromText('POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))', 0), 'BuildingD', 10),
(5, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))', 0), 'BuildingE', 30);

INSERT INTO drogi VALUES
(1, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)', 0), 'RoadX'),
(2, ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)', 0), 'RoadY');

INSERT INTO pktinfo VALUES
(1, ST_GeomFromText('POINT(1 3.5)', 0) , 'G', 5),
(2, ST_GeomFromText('POINT(5.5 1.5)', 0), 'H', 10),
(3, ST_GeomFromText('POINT(9.5 6)', 0), 'I', 6),
(4, ST_GeomFromText('POINT(6.6 6)', 0), 'J', 28),
(5, ST_GeomFromText('POINT(6 9.5)', 0), 'K', 72);

-- SELECT *, ST_AsText(drogi.geometria) AS WKT FROM drogi;

-- 1. Wyznacz całkowitą długość dróg w analizowanym mieście. 
SELECT SUM(ST_Length(geometria)) AS TotalLength FROM drogi;

-- 2. Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego BuildingA. 
SELECT ST_AsText(geometria) AS WKT, ST_Area(geometria) AS Area, ST_Perimeter(geometria) AS Perimeter
FROM budynki
WHERE nazwa = 'BuildingA';

-- 3. Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj 
-- alfabetycznie. 
SELECT nazwa, ST_Area(geometria) AS Area
FROM budynki
ORDER BY nazwa;

-- 4. Wypisz nazwy i obwody 2 budynków o największej powierzchni. 
SELECT nazwa, ST_Perimeter(geometria) AS Perimeter
FROM budynki
ORDER BY ST_Area(geometria) DESC LIMIT (2);

-- 5. Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G. 
SELECT ST_Distance(b.geometria, p.geometria) AS ShortestDistance
FROM budynki AS b, pktinfo AS p
WHERE b.nazwa = 'BuildingC' AND p.nazwa = 'G';

-- 6.  Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej 
--     niż 0.5 od budynku BuildingB.
SELECT ST_Area(ST_Difference((SELECT geometria 
							  FROM budynki
							  WHERE nazwa = 'BuildingC'), 
							  ST_BUFFER((SELECT geometria FROM budynki WHERE nazwa = 'BuildingB'), 0.5))) AS Area;

-- 7. Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi RoadX
SELECT b.nazwa
FROM budynki AS b, drogi AS d
WHERE ST_Y(ST_Centroid(b.geometria)) > ST_Y(ST_Centroid(d.geometria))
AND d.nazwa = 'RoadX';

-- 8. Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych 
-- (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.
SELECT ST_Area(ST_SymDifference((SELECT geometria FROM budynki WHERE nazwa = 'BuildingC'), 
								ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))', 0)))


