-- =============================================================
--  DISCORD CLONE -- Seed data
--  Fixed UUIDs so every exercise file can reference the same rows.
-- =============================================================

USE discord_clone;

INSERT INTO users (id, username) VALUES (11111111-1111-1111-1111-111111111111, 'zephyr');
INSERT INTO users (id, username) VALUES (22222222-2222-2222-2222-222222222222, 'nova_dev');
INSERT INTO users (id, username) VALUES (33333333-3333-3333-3333-333333333333, 'quokka99');

INSERT INTO servers (id, name, owner_id)
  VALUES (aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa, 'DinoPark Devs', 11111111-1111-1111-1111-111111111111);

INSERT INTO channels (id, server_id, name)
  VALUES (bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb, aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa, 'general');
INSERT INTO channels (id, server_id, name)
  VALUES (cccccccc-cccc-cccc-cccc-cccccccccccc, aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa, 'announcements');
