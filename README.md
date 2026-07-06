# 💬 NextGen Python Internship MX Q2 2026 [Stage 2]: Workshop NoSQL DB — Cassandra

**Case study: how Discord stores trillions of chat messages.**

Discord's engineering team has published, in detail, how they store
their message history in Cassandra: partitioned by channel, clustered
by a time-ordered message id, and later re-bucketed by time window
after their largest channels caused hot-partition latency across the
whole cluster.
https://discord.com/blog/how-discord-stores-trillions-of-messages

This session rebuilds a small version of that exact schema, and — on
purpose — recreates the hot-partition problem before fixing it the same
way Discord did.

**Format:** follow-along-with-teacher, not a self-paced tutorial. Some
of you will type every command, others will watch and jump into the
open challenges at the end of each file — both are fine.

---

## Before the session (do this once)

Same WSL2 + Docker Desktop setup as Stage 1 / the MongoDB workshop. If
you've already done that, skip to **Get the workshop files**.

### WSL 2 (Windows Subsystem for Linux)

Open **PowerShell as Administrator**:

```powershell
wsl --install
```

Restart when prompted. Ubuntu will ask you to create a Linux username
and password on first launch.

> Mac users: skip WSL, everything else is the same.

### Docker Desktop

https://www.docker.com/products/docker-desktop/ — check **"Use WSL 2
instead of Hyper-V"** during install, then enable WSL integration for
Ubuntu under **Settings → Resources → WSL Integration**.

### Get the workshop files

```bash
git clone https://github.com/agent3dev/workshop-nosql-stage2-cassandra.git
cd workshop-nosql-stage2-cassandra
```

---

## Session start — bring the cluster up

```bash
docker compose up -d
```

This starts a **real 3-node Cassandra cluster** (not a single instance)
because the consistency-level exercise (04) needs multiple replicas to
mean anything. It also runs a one-off `init` container that waits for
the cluster to be healthy, then loads the schema and seed data.

> ⏱ First start takes a few minutes — 3 JVMs need to boot and gossip
> with each other before the cluster is usable. Needs ~4GB RAM free.

**Verify it's ready:**

```bash
docker compose ps
docker exec discord_cassandra1 nodetool status
```

You should see all 3 nodes as `UN` (Up/Normal). Check the init step
finished:

```bash
docker logs discord_cassandra_init
```

Look for `INIT DONE` at the end.

---

## Connect

Cassandra doesn't have a standard visual tool the way pgAdmin/mongo-
express do — `cqlsh` in the terminal is the normal way to work with it,
including in production.

```bash
docker exec -it discord_cassandra1 cqlsh
```

Try it:

```sql
USE discord_clone;
SELECT * FROM users;
```

You should see 3 seeded users. Type `exit` to leave.

> Every exercise file in this workshop is written to be pasted into
> this same `cqlsh` prompt.

---

## Curriculum

| File | Topic | The Discord need it answers |
|------|-------|------------------------------|
| `exercises/01_crud.cql` | **CRUD basics** | Get comfortable with CQL and where it stops looking like SQL |
| `exercises/02_data_modeling.cql` | **Data modeling: one table per query** | Discord's core read: "last N messages in this channel" |
| `exercises/03_partitions_clustering.cql` | **Partitions & bucketing** | Recreates Discord's real hot-partition postmortem, then fixes it |
| `exercises/04_cql_consistency.cql` | **CQL & consistency levels** | ONE / QUORUM / ALL trade-offs, demoed against real node failure |

Exercise 3 uses a helper script, `exercises/bulk_insert.sh`, to load
enough rows to make partition-size differences visible via `nodetool`.

Take-home challenges are at the end of each file (Part D). Solutions
live in `exercises/solutions/`.

---

## The database

```
servers ──< channels
users
messages_by_channel   -- built in Exercise 2, partitioned by channel_id
messages_by_channel_bucketed -- built in Exercise 3, partitioned by (channel_id, bucket)
```

| Table | What it stores |
|---|---|
| `users` | Seeded once, keyed by `id` |
| `servers` | One seeded server, keyed by `id` |
| `channels` | Two seeded channels, keyed by `id` |
| `messages_*` | Built progressively during the exercises — this is the actual lesson |

---

## Cheat sheet

| What you want | CQL / shell |
|---|---|
| See all rows in a table | `SELECT * FROM users;` |
| Look up by primary key | `SELECT * FROM users WHERE id = ...;` |
| Force a non-key filter (avoid in production) | `... ALLOW FILTERING;` |
| Insert / upsert | `INSERT INTO t (...) VALUES (...);` |
| Delete | `DELETE FROM t WHERE id = ...;` |
| Set consistency for the session | `CONSISTENCY QUORUM;` |
| Cluster health | `docker exec discord_cassandra1 nodetool status` |
| Partition size stats | `docker exec discord_cassandra1 nodetool tablestats discord_clone.<table>` |
| Stop/start a node (simulate failure) | `docker stop discord_cassandra3` / `docker start discord_cassandra3` |

---

## Stop the cluster (when you're done)

```bash
docker compose down
```

Data persists in Docker volumes — `docker compose up -d` again picks up
where you left off (no need to re-run the init step).

---

## Troubleshooting

**`docker compose` command not found**
Try `docker-compose` (hyphenated).

**Nodes stuck in `DN` (Down) or init never finishes**
Cassandra needs real time to bootstrap and reach gossip agreement —
wait a few minutes and re-check `nodetool status`. If a node truly
won't come up, check its logs: `docker logs discord_cassandra2`.

**Machine struggling with 3 nodes**
Each node needs ~512MB heap plus JVM overhead. If your machine can't
handle 3, comment out the `cassandra3` service and change
`replication_factor` to `2` in `init/00_schema.cql` — Exercise 4's ALL
vs QUORUM story still works with 2 nodes, just with a different
majority (2 of 2 instead of 2 of 3).

**Port 9042 already in use**
Another Cassandra is running. Stop it, or change the port mapping in
`docker-compose.yml`.

**Containers stopped after restarting my PC**
Run `docker compose up -d` again — the init container is safe to
re-run (all its statements use `IF NOT EXISTS`).
