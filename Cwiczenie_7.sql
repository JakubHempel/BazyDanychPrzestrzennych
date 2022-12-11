-- 2. Ładowanie danych do tabeli uk_250k
-- raster2pgsql.exe -s 27700 -N -32767 -t 100x100 -I -C -M -d "C:\Users\kubah\Desktop\AGH zajecia\Bazy danych przestrzennych laborki\Cwiczenia_7\ras250_gb\data\*.tif" uk_250k | psql -U postgres -d cwiczenia7 -h localhost -p 5432

SELECT * FROM uk_250k;

-- 3. Połączenie wszystkich kafli w mozaikę
CREATE TABLE uk_250k_union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM uk_250k AS a, national_parks AS b
WHERE ST_Intersects(b.geom, a.rast) AND b.id = '1';

-- 5. Załaduj do bazy danych tabelę reprezentującą granice parków narodowych.
SELECT * FROM national_parks;

-- 6. Utwórz nową tabelę o nazwie uk_lake_district, do której zaimportujesz mapy rastrowe 
-- z punktu 1., które zostaną przycięte do granic parku narodowego Lake District. 
CREATE TABLE uk_lake_district AS 
SELECT ST_Union(ST_Clip(a.rast, b.geom, true)) AS rast
FROM uk_250k AS a, national_parks AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.id = '1';

SELECT * FROM uk_lake_district;
-- DROP TABLE uk_lake_district;

-- 7. Eksport wyniku do pliku GeoTIFF
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM uk_lake_district;

SELECT lo_export(loid, 'D:\uk_lake_district.tiff')
FROM tmp_out;

-- SELECT lo_unlink(loid)
-- FROM tmp_out; --> Delete the large object.

-- 9. Ładowanie danych Sentinela-2
-- raster2pgsql -s 32630 -N -32767 -t 128x128 -I -C -M -d "C:\Users\kubah\Desktop\AGH zajecia\Bazy danych przestrzennych laborki\Cwiczenia_7\sentinel2_B03\*.jp2" sentinel2_B03 | psql -d cwiczenia7 -h localhost -U postgres -p 5432
-- raster2pgsql -s 32630 -N -32767 -t 128x128 -I -C -M -d "C:\Users\kubah\Desktop\AGH zajecia\Bazy danych przestrzennych laborki\Cwiczenia_7\*.jp2" sentinel2_B08 | psql -d cwiczenia7 -h localhost -U postgres -p 5432
SELECT * FROM sentinel2_b03;
SELECT * FROM sentinel2_b08;

-- 10. Indeks NDWI dla parku narodowego Lake District --> NDWI = (Green – NIR)/(Green + NIR) = (Band 3 – Band 8)/(Band 3 + Band 8)
WITH r1 AS (
(SELECT ST_Union(ST_Clip(a.rast, ST_Transform(b.geom, 32630), true)) AS rast
FROM sentinel2_b03 AS a, national_parks AS b
WHERE ST_Intersects(a.rast, ST_Transform(b.geom, 32630)) AND b.id = 1))
,
r2 AS (
(SELECT ST_Union(ST_Clip(a.rast, ST_Transform(b.geom, 32630), true)) AS rast
FROM sentinel2_b08 AS a, national_parks AS b
WHERE ST_Intersects(a.rast, ST_Transform(b.geom, 32630)) AND b.id = 1))

SELECT ST_MapAlgebra(r1.rast, r2.rast, '([rast1.val]-[rast2.val])/([rast1.val]+[rast2.val])::float', '32BF') AS rast
INTO lake_district_ndwi FROM r1, r2;

-- Tworzenie indeksu przestrzennego
CREATE INDEX idx_lake_district_ndwi_rast_gist ON lake_district_ndwi
USING gist(ST_ConvexHull(rast));

-- Dodanie constraintów
SELECT AddRasterConstraints('public'::name, 'lake_district_ndwi'::name, 'rast'::name);

-- 11. Eksport wyniku do pliku GeoTIFF
CREATE TABLE tmp_out_ndwi AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM lake_district_ndwi;

SELECT lo_export(loid, 'D:\lake_district_ndwi.tiff')
FROM tmp_out_ndwi;

-- SELECT lo_unlink(loid)
-- FROM tmp_out_ndwi; --> Delete the large object.

