-- Baseline schema for the logger database.
-- Applied idempotently: safe to run against a fresh database or one already
-- provisioned by the legacy db/init/energo-setup.sh script.

-- datalogger service user
GRANT CONNECT, TEMPORARY ON DATABASE logger TO logger;
GRANT USAGE, CREATE ON SCHEMA public TO logger;

-- grafana read-only user
GRANT CONNECT ON DATABASE logger TO grafana;
GRANT USAGE ON SCHEMA public TO grafana;

-- Auto-grant SELECT on new datalog_* tables to the grafana user, so freshly
-- created per-PLC tables are immediately readable by dashboards.
CREATE OR REPLACE FUNCTION grant_permissions_on_datalog_tables()
RETURNS event_trigger AS $$
DECLARE
    obj record;
BEGIN
    -- Loop through all newly created tables
    FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
    WHERE object_type = 'table'
    LOOP
        -- Check if table name starts with 'datalog_'
        IF obj.object_identity LIKE 'public.datalog_%' THEN
            -- Grant SELECT permission to role
            EXECUTE format('GRANT SELECT ON TABLE %s TO grafana', obj.object_identity);
            RAISE NOTICE 'Granted SELECT on % to grafana', obj.object_identity;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

DROP EVENT TRIGGER IF EXISTS auto_grant_datalog_permissions;
CREATE EVENT TRIGGER auto_grant_datalog_permissions
    ON ddl_command_end
    WHEN TAG IN ('CREATE TABLE')
    EXECUTE FUNCTION grant_permissions_on_datalog_tables();
