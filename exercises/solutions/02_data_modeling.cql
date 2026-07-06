USE discord_clone;

-- D1. "Which channels does a given server have?" -- partition by server_id.
CREATE TABLE IF NOT EXISTS channels_by_server (
    server_id uuid,
    channel_id uuid,
    name text,
    PRIMARY KEY (server_id, channel_id)
);

INSERT INTO channels_by_server (server_id, channel_id, name)
  VALUES (aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa, bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb, 'general');
INSERT INTO channels_by_server (server_id, channel_id, name)
  VALUES (aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa, cccccccc-cccc-cccc-cccc-cccccccccccc, 'announcements');

SELECT * FROM channels_by_server WHERE server_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa;

-- D2. "Last 20 messages across an entire server" -- the partition key
-- has to be server_id (not channel_id), since we want everything in
-- that server regardless of which channel it's in.
CREATE TABLE IF NOT EXISTS messages_by_server (
    server_id  uuid,
    message_id timeuuid,
    channel_id uuid,
    author_id  uuid,
    content    text,
    PRIMARY KEY (server_id, message_id)
) WITH CLUSTERING ORDER BY (message_id DESC);

INSERT INTO messages_by_server (server_id, message_id, channel_id, author_id, content)
  VALUES (aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa, now(), bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,
          11111111-1111-1111-1111-111111111111, 'hey team, standup in 5');

SELECT * FROM messages_by_server WHERE server_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa LIMIT 20;
-- Note: a very active server now has the SAME unbounded-partition risk
-- that a very active channel had in Exercise 3 -- this table needs the
-- same bucket treatment for a real deployment.

-- D3.
DROP TABLE IF EXISTS messages_naive;
