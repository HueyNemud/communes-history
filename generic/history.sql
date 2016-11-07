  CREATE OR REPLACE FUNCTION public.gh_inithistory()
  RETURNS trigger AS
$BODY$
DECLARE
	_wkt_frag_geom text;
	_edge_id integer;
	_frag_table_name character varying;
BEGIN
	_frag_table_name := TG_TABLE_NAME ||'_fragments';
	--1 : Crée la ligne de vie composée d'un unique fragment représenté par une topogeometry allant de [Beginning of time ] à [End of time].
	_wkt_frag_geom  := 'LINESTRING(-1000000 '||NEW.history_uid||', 1000000 '||NEW.history_uid||')';
	SELECT TopoGeo_AddLineString('topo_lifelines',st_geomfromtext(_wkt_frag_geom),0) INTO _edge_id;
	--2 : Enregistrer ce fragment dans la table de fragments lié à cette table historicisée.
	EXECUTE 'INSERT INTO '||_frag_table_name||' VALUES ('||_edge_id||','||NEW.history_uid||', NULL)';
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;

CREATE OR REPLACE FUNCTION public.gh_createhistory(
    history_table_name text,
    schema_name text,
    beginning_of_time date,
    end_of_time date)
  RETURNS integer AS
$BODY$
DECLARE
	_frag_tname character varying;
	_huid_seq_name character varying;
BEGIN
	_frag_tname := $1||'_fragments';
	_huid_seq_name :=$1||'_history_uid_seq';
	
	 IF (SELECT schema_name||'.'||history_table_name::regclass) IS NOT NULL THEN  
		--Creates an identity for each row of the historicized table
		EXECUTE 'ALTER TABLE '||schema_name||'.'||history_table_name||' ADD COLUMN history_uid serial NOT NULL';
		EXECUTE 'ALTER TABLE '||schema_name||'.'||history_table_name||' ADD CONSTRAINT UQ_history_uid UNIQUE (history_uid)';		
		--}
		--Creates the table containing the life fragments of the historicized objects {
		EXECUTE format('CREATE TABLE IF NOT EXISTS %I.%I (edge_id integer, history_id integer, gh_object integer,
			CONSTRAINT %I PRIMARY KEY (edge_id,history_id),
			CONSTRAINT %I UNIQUE (edge_id,history_id,gh_object))', schema_name,_frag_tname,'PK_'||_frag_tname,'UQ_'||_frag_tname);
		--}
		--Add the history initialization trigger to the historicized table {	
		EXECUTE 'CREATE TRIGGER historicize_row AFTER INSERT ON '||schema_name||'.'||history_table_name||' FOR EACH ROW EXECUTE PROCEDURE gh_InitHistory()';
		--}
		RETURN 1;
	END IF;
	RETURN 0;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;

SELECT gh_CreateHistory('communes_france','public','-infinity'::date, 'infinity'::date);
INSERT INTO communes_france(identity) values (1);
