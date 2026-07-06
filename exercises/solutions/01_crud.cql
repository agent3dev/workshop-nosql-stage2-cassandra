USE discord_clone;

-- D1.
INSERT INTO users (id, username) VALUES (99999999-9999-9999-9999-999999999999, 'my_username');
INSERT INTO servers (id, name, owner_id)
  VALUES (88888888-8888-8888-8888-888888888888, 'My Server', 99999999-9999-9999-9999-999999999999);
INSERT INTO channels (id, server_id, name)
  VALUES (77777777-7777-7777-7777-777777777777, 88888888-8888-8888-8888-888888888888, 'my-channel');

-- D2. `channels` is keyed by `id` alone, so looking up by id needs no filtering:
SELECT server_id, name FROM channels WHERE id = bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb;

-- D3. `users` is keyed by `id`, not `username`. Cassandra refuses to scan
-- every partition on every node to find a matching username by default --
-- that's an expensive, unpredictable-latency operation the query
-- planner won't do silently. (A real fix isn't ALLOW FILTERING -- it's
-- a second table `users_by_username` keyed by username, following the
-- same "one table per query" pattern as Exercise 2.)
