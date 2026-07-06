-- D1. A fixed 10-day window sized for Discord's BUSIEST channels wastes
-- almost nothing on quiet channels -- an empty or near-empty bucket
-- costs essentially zero storage in Cassandra, it just isn't written
-- to. The real risk of a fixed window is the opposite case: a channel
-- busier than whatever traffic the window was sized for still grows
-- an oversized bucket. An adaptive/per-channel window is more correct
-- in theory but adds real operational complexity (the app needs to
-- track and look up each channel's chosen bucket size before every
-- write and read); Discord's own writeup describes picking one fixed
-- window empirically from their largest channels rather than building
-- that adaptive system.

-- D2. Re-bucketing messages_by_author (from Exercise 2 Part C):
--   CREATE TABLE messages_by_author_bucketed (
--       author_id  uuid,
--       bucket     bigint,
--       message_id timeuuid,
--       channel_id uuid,
--       content    text,
--       PRIMARY KEY ((author_id, bucket), message_id)
--   ) WITH CLUSTERING ORDER BY (message_id DESC);
-- Yes, a hot author-partition is realistic too -- a very prolific
-- poster (or, worse, a bot account) accumulates messages the same
-- unbounded way a busy channel does. Same problem, same fix.

USE discord_clone;

-- D3.
TRUNCATE messages_by_channel;
TRUNCATE messages_by_channel_bucketed;
