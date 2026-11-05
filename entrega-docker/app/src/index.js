// API de notas: contenedor 1 (aplicación).
// Se conecta al contenedor 2 (PostgreSQL) usando el NOMBRE DEL SERVICIO
// definido en docker-compose.yml ("db"), nunca localhost ni una IP fija.
const express = require('express');
const { Pool } = require('pg');

const PORT = Number(process.env.APP_PORT || 3000);

// Todos los datos de conexión vienen de variables de entorno (archivo .env).
const pool = new Pool({
  host: process.env.DB_HOST, // "db" = nombre del servicio en la red de Docker
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB,
});

const app = express();
app.use(express.json());

// Estado de la app y de la conexión con la base de datos.
app.get('/health', async (req, res) => {
  try {
    const r = await pool.query(
      'SELECT version() AS version, inet_server_addr() AS ip_servidor_db'
    );
    res.json({
      app: 'ok',
      db: 'ok',
      db_host_usado: process.env.DB_HOST,
      ip_resuelta_por_docker: r.rows[0].ip_servidor_db,
      postgres: r.rows[0].version,
    });
  } catch (err) {
    res.status(503).json({ app: 'ok', db: 'error', detalle: err.message });
  }
});

// Ida: guarda una nota en la base de datos (contenedor 2).
app.post('/notas', async (req, res) => {
  const { texto } = req.body || {};
  if (!texto || typeof texto !== 'string') {
    return res.status(400).json({ error: 'El campo "texto" es obligatorio' });
  }
  try {
    const r = await pool.query(
      'INSERT INTO notas (texto) VALUES ($1) RETURNING id, texto, creada_en',
      [texto]
    );
    res.status(201).json(r.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Vuelta: lee las notas guardadas en la base de datos.
app.get('/notas', async (req, res) => {
  try {
    const r = await pool.query('SELECT id, texto, creada_en FROM notas ORDER BY id');
    res.json(r.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/notas/:id', async (req, res) => {
  try {
    const r = await pool.query(
      'SELECT id, texto, creada_en FROM notas WHERE id = $1',
      [req.params.id]
    );
    if (r.rowCount === 0) return res.status(404).json({ error: 'No existe' });
    res.json(r.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`notas-api escuchando en el puerto ${PORT}`);
  console.log(`Conectando a PostgreSQL en el host "${process.env.DB_HOST}"`);
});
