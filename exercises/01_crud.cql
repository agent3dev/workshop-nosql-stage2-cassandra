-- =============================================================
--  DISCORD CLONE -- Exercise 1: CRUD basics
--  Case study: Discord's engineering team has written publicly about
--  storing trillions of messages in Cassandra. Before we rebuild their
--  actual message table (exercises 2-3), let's get comfortable with
--  CQL basics and the ways it's NOT like SQL.
--  https://discord.com/blog/how-discord-stores-trillions-of-messages
-- =============================================================

USE discord_clone;

-- -------------------------------------------------------
-- PART A: Reading what's already there
-- -------------------------------------------------------

-- A1. See everything -- fine for a tiny seed table, never do this on a
--     production-sized Cassandra table (it scans every partition).
SELECT * FROM users;
SELECT * FROM servers;
SELECT * FROM channels;

-- A2. Look up a single row BY PRIMARY KEY -- this is the query pattern
--     Cassandra is built for: fast, single-partition reads.
SELECT * FROM users WHERE id = 11111111-1111-1111-1111-111111111111;

-- A3. Now try filtering on a column that is NOT the primary key:
SELECT * FROM channels WHERE server_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa;
-- This fails: "Cannot execute this query as it might involve data
-- filtering and thus may have unpredictable performance."
-- `channels` is keyed by `id` alone -- server_id was never meant to be
-- queried on directly by this table's design.

-- A4. Cassandra will let you force it through anyway:
SELECT * FROM channels WHERE server_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa ALLOW FILTERING;
-- It "works" here because the table is tiny. At real scale this means
-- scanning every node in the cluster for every request -- this is
-- exactly the trap Exercise 2 is about avoiding by design, not by luck.


-- -------------------------------------------------------
-- PART B: Writing
-- -------------------------------------------------------

-- B1. Insert a new user.
INSERT INTO users (id, username) VALUES (44444444-4444-4444-4444-444444444444, 'tessellate');

-- B2. Insert a new channel on the existing server.
INSERT INTO channels (id, server_id, name)
  VALUES (dddddddd-dddd-dddd-dddd-dddddddddddd, aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa, 'off-topic');

-- B3. Update -- in CQL, INSERT and UPDATE are close to interchangeable
--     for a given primary key (both are "upserts" under the hood).
UPDATE channels SET name = 'off-topic-renamed'
  WHERE id = dddddddd-dddd-dddd-dddd-dddddddddddd;

-- B4. Delete.
DELETE FROM channels WHERE id = dddddddd-dddd-dddd-dddd-dddddddddddd;


-- -------------------------------------------------------
-- PART C: No JOIN -- resolve relationships yourself
-- -------------------------------------------------------

-- C1. "Which server owns the #general channel, and who owns that server?"
--     In SQL (Stage 1) this is one query with two JOINs. In CQL it's
--     always multiple round trips -- the application does the joining.
SELECT server_id FROM channels WHERE id = bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb;
SELECT owner_id, name FROM servers WHERE id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa;
SELECT username FROM users WHERE id = 11111111-1111-1111-1111-111111111111;

-- Question for the class: why would a database deliberately give up
-- JOINs? (Hint: think about what a JOIN costs when "the table" is
-- actually spread across hundreds of machines.)


-- -------------------------------------------------------
-- PART D: Open challenges
-- -------------------------------------------------------

-- D1. Insert yourself as a new user, then a new server you "own",
--     then a channel on that server.

-- D2. Without ALLOW FILTERING, write a query that returns a single
--     channel's server_id and name by the channel's own id. (This
--     should NOT need ALLOW FILTERING -- think about which column
--     the table is actually keyed on.)

-- D3. Try `SELECT * FROM users WHERE username = 'zephyr';` -- explain
--     in your own words why this fails, referencing Part A3.
