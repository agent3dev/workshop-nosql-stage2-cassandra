-- =============================================================
--  DISCORD CLONE -- Exercise 3: Partitions & the hot-partition problem
--  Case study: this is Discord's own postmortem, not a hypothetical.
--  `messages_by_channel` from Exercise 2 partitions by channel_id
--  alone -- meaning ALL of one channel's messages, forever, live in
--  ONE partition on ONE set of replicas. Discord's largest channels
--  eventually made this partition huge enough to cause cluster-wide
--  latency. Their fix: bucket messages by a time window so no single
--  partition grows without bound.
--  https://discord.com/blog/how-discord-stores-trillions-of-messages
-- =============================================================

USE discord_clone;

-- -------------------------------------------------------
-- PART A: Recreate the hot-partition problem
-- -------------------------------------------------------

-- A1. `messages_by_channel` (built in Exercise 2) is partitioned by
--     channel_id ALONE -- every message ever sent in one channel is
--     the SAME partition. In a second terminal (host, not cqlsh),
--     bulk-load 3000 more messages into that one channel:
--
--     ./bulk_insert.sh unbucketed 3000
--
-- A2. Force a flush to disk so nodetool's stats are accurate, then
--     inspect partition-level stats (run from host):
--
--     docker exec discord_cassandra1 nodetool flush discord_clone messages_by_channel
--     docker exec discord_cassandra1 nodetool tablestats discord_clone.messages_by_channel
--
-- Look at "Number of partitions (estimate)": there's only ONE (or a
-- small handful across the other seeded channels), no matter how many
-- thousands of messages you load into that channel. Every one of
-- those rows lives in the exact same partition, on the exact same 3
-- replica nodes. At Discord's real scale -- millions of messages in
-- one wildly active channel -- this is precisely what caused
-- hot-partition latency spikes across the WHOLE cluster, not just
-- reads of that one channel.


-- -------------------------------------------------------
-- PART B: The real fix -- bucket by time window
-- -------------------------------------------------------

-- B1. Add a `bucket` column to the partition key. Discord uses ~10-day
--     windows sized so no bucket exceeds ~100MB. The bucket number is
--     computed by the APPLICATION (e.g. floor(days_since_epoch / 10)),
--     not by Cassandra -- there are no computed columns in CQL.
CREATE TABLE IF NOT EXISTS messages_by_channel_bucketed (
    channel_id uuid,
    bucket     bigint,
    message_id timeuuid,
    author_id  uuid,
    content    text,
    PRIMARY KEY ((channel_id, bucket), message_id)
) WITH CLUSTERING ORDER BY (message_id DESC);

-- B2. In a second terminal, load the SAME 3000 messages, but spread
--     across 10 buckets (simulating ~100 days of real traffic):
--
--     ./bulk_insert.sh bucketed 3000 10
--
-- B3. Compare stats -- now there are 10 partitions instead of 1, each
--     roughly 1/10th the size:
--
--     docker exec discord_cassandra1 nodetool flush discord_clone messages_by_channel_bucketed
--     docker exec discord_cassandra1 nodetool tablestats discord_clone.messages_by_channel_bucketed


-- -------------------------------------------------------
-- PART C: The cost of bucketing -- reads get one step harder
-- -------------------------------------------------------

-- C1. A single bucket read is still a single-partition read (fast):
SELECT * FROM messages_by_channel_bucketed
  WHERE channel_id = bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb AND bucket = 0
  LIMIT 50;

-- C2. But "give me the last 50 messages" now means the app must know
--     WHICH bucket to look in -- normally "today's bucket" -- and if
--     that bucket doesn't have 50 messages yet, fall back to the
--     previous bucket too:
SELECT * FROM messages_by_channel_bucketed
  WHERE channel_id = bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb AND bucket IN (0, 1)
  LIMIT 50;

-- Question for the class: this is a real tradeoff, not a free lunch.
-- What did we give up by adding `bucket` to the partition key, compared
-- to Exercise 2's plain `messages_by_channel`?


-- -------------------------------------------------------
-- PART D: Open challenges
-- -------------------------------------------------------

-- D1. Discord picked a 10-day bucket window sized to stay under 100MB
--     for their BUSIEST channels. A small private server's #general
--     channel might get 10 messages a day. Should its bucket window
--     be the same 10 days? Argue for a fixed window vs. a
--     per-channel/adaptive window.

-- D2. Sketch (in comments, no need to run) how you'd re-bucket
--     `messages_by_author` from Exercise 2 Part C the same way, and
--     whether a hot author-partition is a realistic problem here too.

-- D3. Clean up the bulk test data when you're done:
--     TRUNCATE messages_by_channel;
--     TRUNCATE messages_by_channel_bucketed;
