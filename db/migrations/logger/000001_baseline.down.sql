DROP EVENT TRIGGER IF EXISTS auto_grant_datalog_permissions;
DROP FUNCTION IF EXISTS grant_permissions_on_datalog_tables();

REVOKE USAGE ON SCHEMA public FROM grafana;
REVOKE CONNECT ON DATABASE logger FROM grafana;

REVOKE CREATE, USAGE ON SCHEMA public FROM logger;
REVOKE CONNECT, TEMPORARY ON DATABASE logger FROM logger;
