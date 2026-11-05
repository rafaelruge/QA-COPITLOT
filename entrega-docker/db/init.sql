-- Contenedor 2: PostgreSQL. Este script se ejecuta la primera vez que
-- se crea el volumen de datos (carpeta docker-entrypoint-initdb.d).
CREATE TABLE IF NOT EXISTS notas (
  id         SERIAL PRIMARY KEY,
  texto      TEXT NOT NULL,
  creada_en  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
