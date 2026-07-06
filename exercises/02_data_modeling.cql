-- =============================================================
--  DISCORD CLONE -- Exercise 2: Data Modeling ("one table per query")
--  Case study: Discord's #1 read pattern is "give me the last N
--  messages in this channel, newest first." Their engineering blog
--  is explicit that Cassandra tables must be designed around the
--  QUERY, not around "the entities" the way a relational schema is.
--  This exercise recreates that exact design decision.
-- =============================================================

USE discord_clone;

-- -------------------------------------------------------
-- PART A: The naive, SQL-shaped attempt
-- -------------------------------------------------------

-- A1. If you designed this like a Postgres table, you'd probably key
--     messages by their own id and add a channel_id column -- exactly
--     like Stage 1's `dinosaurs` table style.
CREATE TABLE IF NOT EXISTS messages_naive (
    message_id timeuuid PRIMARY KEY,
    channel_id uuid,
    author_id  uuid,
    content    text
);

INSERT INTO messages_naive (message_id, channel_id, author_id, content)
  VALUES (now(), bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb, 11111111-1111-1111-1111-111111111111, 'hey team, standup in 5');
INSERT INTO messages_naive (message_id, channel_id, author_id, content)
  VALUES (now(), bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb, 22222222-2222-2222-2222-222222222222, 'omw');
INSERT INTO messages_naive (message_id, channel_id, author_id, content)
  VALUES (now(), cccccccc-cccc-cccc-cccc-cccccccccccc, 11111111-1111-1111-1111-111111111111, 'release notes are up');

-- A2. Now ask the ONE question that matters: "last messages in #general".
SELECT * FROM messages_naive WHERE channel_id = bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb;
-- Fails without ALLOW FILTERING -- and even with it, this scans every
-- partition (every message, in every channel, ever) to find the few
-- that match. This is the table Discord explicitly did NOT build.


-- -------------------------------------------------------
-- PART B: Design the table around the query -- Discord's real schema
-- -------------------------------------------------------

-- B1. Partition by channel_id (so all of one channel's messages live
--     together), cluster by message_id descending (so "newest first"
--     is free -- no in-memory sort needed).
CREATE TABLE IF NOT EXISTS messages_by_channel (
    channel_id uuid,
    message_id timeuuid,
    author_id  uuid,
    content    text,
    PRIMARY KEY (channel_id, message_id)
) WITH CLUSTERING ORDER BY (message_id DESC);

-- B2. Same three messages, same data, but written to the table shaped
--     around the read we actually need.
INSERT INTO messages_by_channel (channel_id, message_id, author_id, content)
  VALUES (bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb, now(), 11111111-1111-1111-1111-111111111111, 'hey team, standup in 5');
INSERT INTO messages_by_channel (channel_id, message_id, author_id, content)
  VALUES (bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb, now(), 22222222-2222-2222-2222-222222222222, 'omw');
INSERT INTO messages_by_channel (channel_id, message_id, author_id, content)
  VALUES (cccccccc-cccc-cccc-cccc-cccccccccccc, now(), 11111111-1111-1111-1111-111111111111, 'release notes are up');

-- B3. The query Discord actually runs millions of times a second:
SELECT * FROM messages_by_channel WHERE channel_id = bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb LIMIT 50;
-- No ALLOW FILTERING needed. Single partition read. Already sorted
-- newest-first because of CLUSTERING ORDER.

-- Why timeuuid? It's globally unique (no collisions across multiple
-- app servers writing concurrently) AND naturally time-ordered, which
-- is exactly what Discord's Snowflake message IDs give them too.


-- -------------------------------------------------------
-- PART C: "One table per query" means duplicating data on write
-- -------------------------------------------------------

-- C1. Want "all messages by a given author, across every channel,
--     newest first"? That's a DIFFERENT query, so it's a DIFFERENT
--     table -- populated by writing to BOTH tables on every insert.
CREATE TABLE IF NOT EXISTS messages_by_author (
    author_id  uuid,
    message_id timeuuid,
    channel_id uuid,
    content    text,
    PRIMARY KEY (author_id, message_id)
) WITH CLUSTERING ORDER BY (message_id DESC);

INSERT INTO messages_by_author (author_id, message_id, channel_id, content)
  VALUES (11111111-1111-1111-1111-111111111111, now(), bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb, 'hey team, standup in 5');

SELECT * FROM messages_by_author WHERE author_id = 11111111-1111-1111-1111-111111111111 LIMIT 50;

-- Question for the class: in Postgres (Stage 1) you'd never store the
-- same row twice on purpose. Why does that tradeoff make sense here?
-- (Hint: what does Cassandra give up -- see Exercise 1 Part C -- in
-- exchange for every query being a single-partition read?)


-- -------------------------------------------------------
-- PART D: Open challenges
-- -------------------------------------------------------

-- D1. Design (CREATE TABLE) a table that answers: "which channels
--     does a given server have?" -- without ALLOW FILTERING. Populate
--     it from the seeded `channels` data.

-- D2. Design a table that answers: "what are the last 20 messages
--     across an ENTIRE SERVER, regardless of channel, newest first?"
--     (Hint: what would the partition key have to be?)

-- D3. `messages_naive` from Part A is now dead weight -- drop it:
--     DROP TABLE messages_naive;
