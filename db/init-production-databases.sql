-- Create extra databases for production (primary is created via POSTGRES_DB).
-- Runs automatically when the Postgres container is first initialized.
CREATE DATABASE url_shortener_production_cache;
CREATE DATABASE url_shortener_production_queue;
CREATE DATABASE url_shortener_production_cable;
