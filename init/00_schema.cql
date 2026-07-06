-- =============================================================
--  DISCORD CLONE -- Keyspace + base tables
--  Workshop NoSQL Stage 2 -- Cassandra
-- =============================================================
-- The `messages` table -- the actual heart of this case study --
-- is deliberately NOT created here. Designing it correctly is
-- exercises 2 and 3. This file only seeds the tables students
-- need before that point: users, servers, channels.

CREATE KEYSPACE IF NOT EXISTS discord_clone
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};

USE discord_clone;

CREATE TABLE IF NOT EXISTS users (
    id       uuid PRIMARY KEY,
    username text
);

CREATE TABLE IF NOT EXISTS servers (
    id       uuid PRIMARY KEY,
    name     text,
    owner_id uuid
);

CREATE TABLE IF NOT EXISTS channels (
    id        uuid PRIMARY KEY,
    server_id uuid,
    name      text
);
