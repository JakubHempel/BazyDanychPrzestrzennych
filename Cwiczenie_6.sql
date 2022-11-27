-- Zmiana nazwy schematu schema_name
ALTER SCHEMA schema_name RENAME TO hempel;

-- TWORZENIE RASTRÓW Z ISTNIEJĄCYCH RASTRÓW Z INTERAKCJĄ Z WEKTORAMI
-- Przykład 1. - Przycięcie rastra z wektorem
CREATE TABLE hempel.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';  -- ilike none case-sensitive LIKE

SELECT * FROM hempel.intersects;

-- Dodanie serial primary key
ALTER TABLE hempel.intersects
ADD COLUMN rid SERIAL PRIMARY KEY; -- SERIAL datatype allows automatically generate unique int numbers

-- Utworzenie indeksu przestrzennego
CREATE INDEX idx_intersects_rast_gist ON hempel.intersects
USING gist (ST_ConvexHull(rast)); -- ST_ConvexHull - oblicza otoczkę wypukłą geometrii

-- Dodanie raster constraints
-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('hempel'::name,
'intersects'::name,'rast'::name);

-- Przykład 2. - ST_Clip
-- Obcinanie rastra na podstawie wektora
CREATE TABLE hempel.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

-- Przykład 3. - ST_Union
-- Połączenie wielu kafelków w jeden raster
CREATE TABLE hempel.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);


-- TWORZENIE RASTRÓW Z WEKTORÓW (rastrowanie)
-- Przykład 1. - ST_AsRaster
CREATE TABLE hempel.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- Przykład 2. - ST_Union
DROP TABLE hempel.porto_parishes; --> drop table porto_parishes first
CREATE TABLE hempel.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- Przykład 3. - ST_Tile
DROP TABLE hempel.porto_parishes; --> drop table porto_parishes first
CREATE TABLE hempel.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- KONWERTOWANIE RASTRÓW NA WEKTORY (wektoryzowanie)
-- Przykład 1. - ST_Intersection
CREATE TABLE hempel.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przykład 2. - ST_DumpAsPolygons
-- konwertuje rastry na wektory (poligony)
CREATE TABLE hempel.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- ANALIZA RASTRÓW
-- Przykład 1. - ST_Band
CREATE TABLE hempel.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

-- Przykład 2. - ST_Clip
CREATE TABLE hempel.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przykład 3. - ST_Slope - generowanie nachylenia
CREATE TABLE hempel.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM hempel.paranhos_dem AS a;

-- Przykład 4. ST_Reclass - reklasyfikacja rastra
CREATE TABLE hempel.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM hempel.paranhos_slope AS a;

-- Przykład 5. - ST_SummaryStats - obliczanie statystyk rastra
SELECT ST_SummaryStats(a.rast) AS stats
FROM hempel.paranhos_dem AS a;

-- Przykład 6. - ST_SummaryStats oraz Union
SELECT ST_SummaryStats(ST_Union(a.rast))
FROM hempel.paranhos_dem AS a;

-- Przykład 7. - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT ST_SummaryStats(ST_Union(a.rast)) AS stats
FROM hempel.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

-- Przykład 8 - ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
SELECT b.parish AS parish, ST_SummaryStats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

-- Przykład 9 - ST_Value
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

-- TOPOGRAPHIC POSITION INDEX (TPI)
-- Przykład 10 - ST_TPI
CREATE TABLE hempel.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

-- Stworzenie indeksu przestrzennego
CREATE INDEX idx_tpi30_rast_gist ON hempel.tpi30
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów
SELECT AddRasterConstraints('hempel'::name,
'tpi30'::name,'rast'::name);

-- Problem do samodzielnego zrealizowania
CREATE TABLE hempel.tpi30_intersects AS 
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

SELECT * FROM hempel.tpi30_intersects;

-- Tworzenie indeksu przestrzennego
CREATE INDEX idx_tpi30_rast_gist_intersects ON hempel.tpi30_intersects
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów
SELECT AddRasterConstraints('hempel'::name,
'tpi30_intersects'::name,'rast'::name);

-- zrobić porównanie czasów zapytań dla tpi30 i tpi30_intersects

-- ALGEBRA MAP
-- Przykład 1. - Wyrażenie Algebry Map
CREATE TABLE hempel.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

-- Tworzenie indeksu przestrzennego
CREATE INDEX idx_porto_ndvi_rast_gist ON hempel.porto_ndvi
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów
SELECT AddRasterConstraints('hempel'::name,
'porto_ndvi'::name,'rast'::name);

-- Przykład 2. - Funkcja zwrotna
create or replace function hempel.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE hempel.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'hempel.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
) AS rast
FROM r;

-- Tworzenie indeksu przestrzennego
CREATE INDEX idx_porto_ndvi2_rast_gist ON hempel.porto_ndvi2
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów
SELECT AddRasterConstraints('hempel'::name,
'porto_ndvi2'::name,'rast'::name);

-- Przykład 3. - Funkcje TPI
-- funkcja _st_tpi4ma oraz _st_tpi

-- EKSPORT DANYCH
-- Przykład 0 - Użycie QGIS
CREATE TABLE hempel.porto_ndvi_qgis AS 
SELECT ST_Union(rast) FROM hempel.porto_ndvi;

-- Przykład 1 - ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM hempel.porto_ndvi;

-- Przykład 2 - ST_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM hempel.porto_ndvi;

-- Przykład 3 - Zapisywanie danych na dysku za pomocą dużego obiektu (large object, lo)
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM hempel.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'D:\porto_ndvi.tiff') --> Save the file in a place
-- where the user postgres have access. In windows a flash drive usualy works
-- fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

-- Przykład 4 - Użycie Gdal
gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 PG:"host=localhost port=5432 dbname=cwiczenia6 user=postgres password=Siatka07 schema=hempel table=porto_ndvi mode=2" "C:\Users\kubah\Desktop\AGH zajecia\Bazy danych przestrzennych laborki\Cwiczenia_6\rasters\porto_ndvi_gdal.tiff"

-- PUBLIKOWANIE DANYCH ZA POMOCĄ MapServer
-- Przykład 1 - Mapfile
http://127.0.0.1:8082/cgi-bin/mapserv.exe?map=C:/ms4w/apps/local-demo/dem.map&MODE=browse&TEMPLATE=openlayers&LAYERS=all

-- GEOSERVER
CREATE TABLE public.mosaic (
    name character varying(254) COLLATE pg_catalog."default" NOT NULL,
    tiletable character varying(254) COLLATE pg_catalog."default" NOT NULL,
    minx double precision,
    miny double precision,
    maxx double precision,
    maxy double precision,
    resx double precision,
    resy double precision,
    CONSTRAINT mosaic_pkey PRIMARY KEY (name, tiletable)
);
insert into mosaic (name,tiletable) values ('mosaicpgraster','rasters.dem');

SELECT * FROM public.mosaic;

http://localhost:9000/geoserver/bdp_rasters/wms?service=WMS&version=1.1.0&request=GetMap&layers=bdp_rasters%3Amosaicpgraster&bbox=-58968.422190841186%2C147735.24369472192%2C13425.075426302268%2C206234.67734020395&width=768&height=620&srs=EPSG%3A3763&styles=&format=application/openlayers