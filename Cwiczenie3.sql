-- 1. Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana
-- pomiędzy 2018 a 2019).
CREATE TABLE buildingsNew AS (
	SELECT b19.* FROM t2019_kar_buildings as b19
	LEFT JOIN t2018_kar_buildings as b18 
	USING (polygon_id)
	WHERE b18.polygon_id IS NULL OR NOT b19.geom = b18.geom
);

SELECT * FROM buildingsNew;
-- DROP TABLE buildingsNew;

-- 2. Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub
-- wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.
SELECT pt19.type, COUNT(DISTINCT pt19.*) AS POI_number
FROM buildingsNew AS b, t2019_kar_poi_table AS pt19 
LEFT JOIN t2018_kar_poi_table AS pt18
USING (poi_id)
WHERE pt18.poi_id IS NULL AND ST_DWithin(b.geom, pt19.geom, 500)
GROUP BY pt19.type;
s
-- 3. Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
-- T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.
CREATE TABLE streets_reprojected AS (
	SELECT gid, link_id, st_name, ref_in_id, nref_in_id, func_class, speed_cat, fr_speed_l, to_speed_l, dir_travel, 
	ST_Transform(geom, 3068) AS geom
	FROM t2019_kar_streets
);

SELECT * FROM streets_reprojected
-- DROP TABLE streets_reprojected

-- 4. Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
-- Użyj następujących współrzędnych: (8.36093 49.03174); (8.39876 49.00644)
-- Przyjmij układ współrzędnych GPS.
CREATE TABLE input_points(
	id CHAR(2) PRIMARY KEY NOT NULL,
	geom GEOMETRY
);

INSERT INTO input_points VALUES
('P1', ST_GeomFromText('POINT(8.36093 49.03174)', 4326)),
('P2', ST_GeomFromText('POINT(8.39876 49.00644)', 4326));

SELECT id, ST_AsText(geom) FROM input_points;
-- DROP TABLE input_points;

-- 5. Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych
-- DHDN.Berlin/Cassini. Wyświetl współrzędne za pomocą funkcji ST_AsText().
UPDATE input_points
SET geom = ST_Transform(geom, 3068);

SELECT ST_AsText(geom) FROM input_points;

-- 6.  Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej
-- z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj
-- reprojekcji geometrii, aby była zgodna z resztą tabel.
SELECT * FROM t2019_kar_street_node AS strn
WHERE ST_DWithin((SELECT ST_MakeLine(geom) FROM input_points), ST_Transform(strn.geom, 3068), 200);
						 																					 
-- 7. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
-- w odległości 300 m od parków (LAND_USE_A).
SELECT COUNT(DISTINCT pt.*) 
FROM t2019_kar_poi_table AS pt, t2019_kar_land_use_a AS lu
WHERE pt.type = 'Sporting Goods Store' AND lu.type = 'Park (City/County)' 
AND ST_DWithin(pt.geom, lu.geom, 300);

-- 8. Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz
-- znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’
CREATE TABLE t2019_kar_bridges AS (
	SELECT ST_Intersection(r.geom, wl.geom) AS Geom 
	FROM t2019_kar_railways AS r, t2019_kar_water_lines AS wl
	WHERE ST_Intersects(r.geom, wl.geom)
);

SELECT * FROM t2019_kar_bridges;
--DROP TABLE t2019_kar_bridges;
