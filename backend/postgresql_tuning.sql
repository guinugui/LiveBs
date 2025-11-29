# PostgreSQL High Performance Configuration
# Para aplicar: execute como administrador PostgreSQL

# CONNECTIONS
ALTER SYSTEM SET max_connections = 500;
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';

# MEMORY
ALTER SYSTEM SET shared_buffers = '1GB';
ALTER SYSTEM SET effective_cache_size = '3GB';  
ALTER SYSTEM SET work_mem = '16MB';
ALTER SYSTEM SET maintenance_work_mem = '256MB';

# CHECKPOINTS
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

# QUERY PERFORMANCE  
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;

# LOGGING (para produção, desabilitar logs desnecessários)
ALTER SYSTEM SET log_statement = 'none';
ALTER SYSTEM SET log_duration = off;
ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM SET log_temp_files = 0;

# AUTOVACUUM (importante para performance)
ALTER SYSTEM SET autovacuum = on;
ALTER SYSTEM SET autovacuum_max_workers = 4;
ALTER SYSTEM SET autovacuum_naptime = '30s';

# Aplicar mudanças (requer restart do PostgreSQL)
-- Para aplicar execute: pg_ctl restart -D /path/to/data
-- Ou no Windows: net stop postgresql-x64-14 && net start postgresql-x64-14

SELECT pg_reload_conf(); -- Aplica algumas configurações sem restart