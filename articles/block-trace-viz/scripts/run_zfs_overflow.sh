#!/bin/bash
set -eu

echo "=== Phase 1: Normal writes (5s) ==="
blktrace -d /dev/vdc -o zfs_p1 -D /tmp/trace -w 10 &
BT=$!
sleep 1

fio --name=randwrite --filename=/testpool/testfile \
    --rw=randwrite --bs=4k --size=4G \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=5 --output=/tmp/trace/fio_zfs_p1.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true
sleep 1

echo "=== Taking snapshot ==="
zfs snapshot testpool@snap1
echo "=== Snapshot taken. Pool status: ==="
zpool list

echo "=== Phase 2: COW writes with snapshot (writes until ENOSPC or 30s) ==="
blktrace -d /dev/vdc -o zfs_p2 -D /tmp/trace -w 40 &
BT=$!
sleep 1

fio --name=randwrite --filename=/testpool/testfile \
    --rw=randwrite --bs=4k --size=4G \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=30 --output=/tmp/trace/fio_zfs_p2.log || true

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true

echo "=== Final pool status: ==="
zpool list
zpool status testpool
zfs list -t all
echo "=== Done ==="
