  CREATE OR REPLACE FUNCTION public.gh_CreateHistory()
  RETURNS trigger AS
$BODY$
DECLARE
	_wkt_frag_geom text;
	_edge_id integer;
BEGIN
	--1 : Crée la ligne de vie composée d'un unique fragment représenté par une topogeometry allant de [Beginning of time ] à [End of time].
	_wkt_frag_geom  := 'LINESTRING(-1000000 '||NEW.history||', 1000000 '||NEW.history||')';
	SELECT TopoGeo_AddLineString('topo_lifelines',st_geomfromtext(_wkt_frag_geom),0) INTO _edge_id;
	--2 : Enregistrer ce fragment dans la table de fragments lié à cette table historicisée.
	EXECUTE 'INSERT INTO '||_frag_table_name||' VALUES ('||_edge_id||','||NEW.history_uid||', NULL)';
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;
 
  
-- HISTORY CREATION FUNCTION
DROP FUNCTION IF EXISTS public.gh_Historicize(text,text,date,date);

--Convenience function to create the tables necessary to store and maintain the history of geohistorical objects.
CREATE OR REPLACE FUNCTION public.gh_Historicize(
    history_name text,
    schema_name text)
  RETURNS integer AS
$BODY$
DECLARE
BEGIN
	--Create -if not exists- a topology schema dedicated to store the timelines{
	EXECUTE format('');
	--}
	
	--Creates the history table containing the timeline of each entity stored as a list of periods{
	EXECUTE format('CREATE TABLE IF NOT EXISTS %I.%I (history integer, part integer,
		PRIMARY KEY (history,part),
		UNIQUE (part))',--An history part is part of only one history
		schema_name,history_name);
	--}
	-- Creates the fragment table which stores all the gh_object referenced by each history part{
	EXECUTE format('CREATE TABLE IF NOT EXISTS %1$I.%2$I (history integer NOT NULL, part integer NOT NULL, gh_object integer, gh_object_tblname text,
		CHECK ((gh_object IS NULL OR  gh_object_tblname IS NOT NULL) AND (gh_object_tblname IS NULL OR gh_object IS NOT NULL)),
		FOREIGN KEY (history,part) REFERENCES %1$I.%3$I (history,part),
		PRIMARY KEY (part,gh_object) )',
		schema_name,history_name||'_fragments',history_name);
	--}
	EXECUTE 'CREATE TRIGGER '
	RETURN 1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;

CREATE OR REPLACE FUNCTION gh_AddHistory() RETURNS integer AS
$$
$$
  LANGUAGE plpgsql VOLATILE STRICT;



  
--Fonctions générales
gh_Historicize('communes_france','public','-infinity'::date, 'infinity'::date); -- Définition d'une architecture d'objets hsitoricisés.
gh_UnHistoricize(an__historicized_object); -- WARNING : supprime tout l'historique d'un type d'objet!
gh_VerifyHistories() --Vérifie que toute la base est cohérente (topologie + lien évènements/chronologies)

--Fonctions sur l'historique d'un évènement.
gh_InsertEvent(an_event integer, a_history integer, role json); -- Ajoute un évènement à l'histoire d'un objet. L'objet peut jouer un rôle dans l'évènement (stocké comme JSON pour pouvoir mettre n'importe quoi comme rôle?).
gh_RemoveEvent(an_event integer) -- Retire l'évènement d'une histoire et mets à jour la chronologie.
gh_CheckHistory(a_history integer) --Vérifie qu'une histoire est cohérente, c'est à dire que la chronologie est cohérente avec les évènements rattachés à cette histoire + que la topologie est cohérente. Cette fonction devrait etre appelée après toute fonction qui modifie une histoire.
gh_AttachFragment(a_history integer, a_history_part integer, a_GeohistoricalObject text,the_geohistoricalobject_table text,the_geohistoricalobject_schema text,the_object_role text) --Attache un objet géohistorique à une partie de la chronologie d'un objet.
gh_AttachFragment(a_history integer, a_date_or_a_daterange daterange, a_GeohistoricalObject text,the_geohistoricalobject_table text,the_geohistoricalobject_schema text,the_object_role text) -- Attache un objet géohistorique à toutes les parties de chronologie qui sont couvertes par la date.
gh_DetachFragment(a_history integer, a_history_part integer, a_GeohistoricalObject text) --Détache un objet géohistorique à une partie de la chronologie d'un objet.
gh_BuildHistory(an_history integer) -- Renvoie, sous la forme d'une table, tout l'historique d'un objet. La table contient autant de colonnes qu'ils y a d'objets géohistoriques de type différends attachés aux différents fragments de l'historique.

--Fonctions sur les évènements
--Un évènement est un geohistoricalobject avec en plus un identifiant unique pour garantir l'unicité de façon plus stricte.
--Un évènement peut avoir une géométrie, ou non.
gh_AddEvent(???) -- Crée un nouvel évènement et l'ajoute à la table des évènements.
gh_DeleteEvent(an_event integer) -- Supprime l'évènement et mets à jour la chronologie de toutes les histoires qui en dépendent.
gh_UpdateHistories(an_event integer) -- Mets à jours toutes les histoires qui utilisent cet évènement. Doit être appelée quand la date d'un évènement est modifiée.







SELECT topology.AddTopoGeometryColumn('topo_lifelines','public','communes_france','topo','LINE');
INSERT INTO toTopoGeom(st_geomfromtext('LINESTRING(0 0, 100 0)'),'topo_lifelines',2,0);

SELECT * from topo_lifelines.edge_data;
SELECT * from topo_lifelines.relation;

DELETE FROM topo_lifelines.edge_data;
DELETE FROM topo_lifelines.node;
DELETE FROM topo_lifelines.relation;

CREATE TABLE test (text_column text, geometry_column geometry, another_column text, UNIQUE (text_column,geometry_column));
INSERT INTO test VALUES ('A',st_point(100,100))