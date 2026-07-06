#!/usr/bin/env bash
# Helper for Exercise 3 -- generates many INSERT statements as ONE batch
# file and runs it through cqlsh once (much faster than one cqlsh
# process per row). Run this from your HOST terminal, not inside cqlsh.
#
# Usage:
#   ./bulk_insert.sh unbucketed <count>
#       -- inserts <count> rows into messages_by_channel (from Exercise 2),
#          all under the SAME channel_id -- i.e. all in the SAME
#          partition, since that table's partition key is channel_id
#          alone. This is the unbounded-partition problem from Discord's
#          real postmortems.
#
#   ./bulk_insert.sh bucketed <count> <buckets>
#       -- inserts <count> rows into messages_by_channel_bucketed,
#          spread evenly across <buckets> bucket values -- simulating
#          what Discord's real 10-day time-bucketing achieves.
set -euo pipefail

MODE="${1:?mode required: unbucketed|bucketed}"
COUNT="${2:?row count required}"
CHANNEL_ID="bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
AUTHOR_ID="11111111-1111-1111-1111-111111111111"
TMP_FILE="$(mktemp)"

echo "USE discord_clone;" > "$TMP_FILE"

case "$MODE" in
  unbucketed)
    for i in $(seq 1 "$COUNT"); do
      echo "INSERT INTO messages_by_channel (channel_id, message_id, author_id, content) VALUES ($CHANNEL_ID, now(), $AUTHOR_ID, 'bulk message $i');" >> "$TMP_FILE"
    done
    ;;
  bucketed)
    BUCKETS="${3:?bucket count required for bucketed mode}"
    for i in $(seq 1 "$COUNT"); do
      BUCKET=$(( i % BUCKETS ))
      echo "INSERT INTO messages_by_channel_bucketed (channel_id, bucket, message_id, author_id, content) VALUES ($CHANNEL_ID, $BUCKET, now(), $AUTHOR_ID, 'bulk message $i');" >> "$TMP_FILE"
    done
    ;;
  *)
    echo "Unknown mode: $MODE (expected unbucketed|bucketed)" >&2
    exit 1
    ;;
esac

docker exec -i discord_cassandra1 cqlsh < "$TMP_FILE"
rm -f "$TMP_FILE"
echo "Inserted $COUNT rows in mode '$MODE'."
