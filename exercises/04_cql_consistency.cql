-- =============================================================
--  DISCORD CLONE -- Exercise 4: CQL Consistency Levels
--  Case study: our compose file runs a 3-node cluster with
--  replication_factor = 3, same shape as a real Cassandra deployment.
--  Consistency levels are the tradeoff Discord (and every Cassandra
--  user) makes explicit at query time: how many of the 3 replicas
--  must respond before a read/write is considered successful?
-- =============================================================

USE discord_clone;

-- -------------------------------------------------------
-- PART A: See the cluster
-- -------------------------------------------------------

-- A1. From the HOST terminal (not cqlsh):
--
--     docker exec discord_cassandra1 nodetool status
--
-- All 3 nodes should show "UN" (Up/Normal). Note the "Owns" column --
-- with RF=3 on a 3-node cluster, every node has a full copy of the data.


-- -------------------------------------------------------
-- PART B: Consistency levels while everything is healthy
-- -------------------------------------------------------

-- B1. ONE -- fastest, only 1 of 3 replicas needs to respond.
CONSISTENCY ONE;
INSERT INTO users (id, username) VALUES (55555555-5555-5555-5555-555555555555, 'consistency_test_one');
SELECT * FROM users WHERE id = 55555555-5555-5555-5555-555555555555;

-- B2. QUORUM -- majority of replicas (2 of 3) must respond. This is
--     what most production Cassandra reads/writes actually use.
CONSISTENCY QUORUM;
INSERT INTO users (id, username) VALUES (66666666-6666-6666-6666-666666666666, 'consistency_test_quorum');
SELECT * FROM users WHERE id = 66666666-6666-6666-6666-666666666666;

-- B3. ALL -- every replica must respond. Strongest consistency,
--     weakest availability (any single node down breaks every query).
CONSISTENCY ALL;
SELECT * FROM users WHERE id = 66666666-6666-6666-6666-666666666666;


-- -------------------------------------------------------
-- PART C: Simulate a node failure -- the tradeoff becomes real
-- -------------------------------------------------------

-- C1. In your HOST terminal, stop one of the three replicas:
--
--     docker stop discord_cassandra3
--
-- C2. Back in cqlsh, try ALL again:
CONSISTENCY ALL;
SELECT * FROM users WHERE id = 66666666-6666-6666-6666-666666666666;
-- Fails: "Cannot achieve consistency level ALL" -- only 2 of 3
-- replicas are reachable now.

-- C3. QUORUM still works -- 2 of 3 is still a majority:
CONSISTENCY QUORUM;
SELECT * FROM users WHERE id = 66666666-6666-6666-6666-666666666666;

-- C4. ONE obviously still works too:
CONSISTENCY ONE;
SELECT * FROM users WHERE id = 66666666-6666-6666-6666-666666666666;

-- C5. Restore the node from your HOST terminal when done:
--
--     docker start discord_cassandra3
--
-- Give it ~20-30 seconds to rejoin before continuing.


-- -------------------------------------------------------
-- PART D: Open challenges
-- -------------------------------------------------------

-- D1. Discord's real message-storage use case tolerates ONE/QUORUM --
--     an occasional stale read (a message that's slightly delayed
--     appearing to one user) is an acceptable tradeoff for speed and
--     availability at massive scale. Name a DIFFERENT feature of a
--     chat app (still plausibly stored in Cassandra) where you'd want
--     stronger consistency, and say which level you'd pick and why.

-- D2. With RF=3 and CONSISTENCY QUORUM on both writes and reads, you
--     get "read-your-writes" consistency (a write acked by 2 replicas
--     always overlaps with a read that checks 2 replicas). Write out
--     -- in a comment, no need to run it -- why that overlap is
--     guaranteed. (Hint: with 3 replicas, can 2 written-to nodes and
--     2 read-from nodes ever have ZERO nodes in common?)

-- D3. Stop TWO nodes (discord_cassandra2 AND discord_cassandra3) and
--     try QUORUM. What happens, and why does this match "majority of
--     3 is 2, not 1"?
