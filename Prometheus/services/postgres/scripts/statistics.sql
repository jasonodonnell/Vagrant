CREATE USER postgres_exporter LOGIN;
GRANT CONNECT ON DATABASE postgres TO postgres_exporter;
ALTER USER postgres_exporter SET SEARCH_PATH TO postgres_exporter,pg_catalog;

CREATE SCHEMA postgres_exporter AUTHORIZATION postgres_exporter;

CREATE FUNCTION postgres_exporter.f_select_pg_stat_activity()
RETURNS setof pg_catalog.pg_stat_activity
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT * from pg_catalog.pg_stat_activity;
$$;

CREATE FUNCTION postgres_exporter.f_select_pg_stat_replication()
RETURNS setof pg_catalog.pg_stat_replication
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT * from pg_catalog.pg_stat_replication;
$$;

CREATE VIEW postgres_exporter.pg_stat_replication
AS
  SELECT * FROM postgres_exporter.f_select_pg_stat_replication();

CREATE VIEW postgres_exporter.pg_stat_activity
AS
  SELECT * FROM postgres_exporter.f_select_pg_stat_activity();

GRANT SELECT ON postgres_exporter.pg_stat_replication TO postgres_exporter;
GRANT SELECT ON postgres_exporter.pg_stat_activity TO postgres_exporter;
