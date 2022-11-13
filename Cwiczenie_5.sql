CREATE TABLE obiekty (
	id INT PRIMARY KEY NOT NULL,
	name VARCHAR(15) NOT NULL,
	geom GEOMETRY NOT NULL
);

-- DROP TABLE obiekty;

-- obiekt1
INSERT INTO obiekty VALUES
(1, 'obiekt1', 
 ST_GeomFromEWKT('SRID=0; COMPOUNDCURVE((0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))'));

SELECT * FROM obiekty WHERE id = 1;

-- obiekt2
INSERT INTO obiekty VALUES
(2, 'obiekt2', 
 ST_GeomFromEWKT('SRID=0; CURVEPOLYGON(
				 COMPOUNDCURVE((10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2), (10 2, 10 6)), 
				 CIRCULARSTRING(11 2, 13 2, 11 2))'));
 
-- obiekt3
INSERT INTO obiekty VALUES
(3, 'obiekt3',
 ST_GeomFromEWKT('SRID=0; CURVEPOLYGON(COMPOUNDCURVE((7 15, 10 17),(10 17, 12 13),(12 13, 7 15)))'));
 
-- obiekt4
INSERT INTO obiekty VALUES
(4, 'obiekt4', 
 ST_GeomFromEWKT('SRID=0; COMPOUNDCURVE((20 20, 25 25),(25 25, 27 24),(27 24, 25 22),(25 22, 26 21),(26 21, 22 19),(22 19, 20.5 19.5))'));
 
-- obiekt5
INSERT INTO obiekty VALUES
(5, 'obiekt5',
 ST_GeomFromEWKT('SRID=0; MULTIPOINTZ((30 30 59), (38 32 234))'));
  
-- obiekt6
INSERT INTO obiekty VALUES
(6, 'obiekt6',
 ST_GeomFromEWKT('SRID=0; GEOMETRYCOLLECTION(POINT(4 2), LINESTRING(1 1, 3 2))'));
  
-- 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej
-- obiekt 3 i 4.
SELECT ST_Area(ST_Buffer(ST_ShortestLine(o3.geom, o4.geom), 5)) AS Area
FROM obiekty AS o3, obiekty AS o4  
WHERE o3.name = 'obiekt3' AND o4.name = 'obiekt4';

-- 2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te
-- warunki.	
UPDATE obiekty 
SET geom = (SELECT ST_MakePolygon(ST_LineMerge(ST_Collect((geom),'LINESTRING(20.5 19.5, 20 20)'))))
WHERE id = 4;

-- 3. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.
INSERT INTO obiekty VALUES
(7, 'obiekt7',
 (SELECT ST_Collect(o3.geom, o4.geom)
  FROM obiekty AS o3, obiekty AS o4 
  WHERE o3.name = 'obiekt3' AND o4.name = 'obiekt4'));
  
SELECT * FROM obiekty WHERE id = 7;

-- DELETE FROM obiekty WHERE id = 7;

-- 4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie
-- zawierających łuków.
SELECT SUM(ST_Area(ST_Buffer(geom, 5))) AS AreaOfBuffers
FROM obiekty
WHERE NOT ST_HasArc(geom);
