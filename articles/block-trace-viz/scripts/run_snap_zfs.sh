#!/bin/bash
set -eu

echo "=== ZFS Phase 1: Normal writes (5s) ==="
blktrace -d /dev/vdc -o zfs_p1 -D /tmp/trace -w 10 &
BT=$!
sleep 1

fio --name=randwrite --filename=/testpool/testfile \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=5 --output=/tmp/trace/fio_zfs_p1.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true
sleep 1

echo "=== ZFS: Taking snapshot ==="
zfs snapshot testpool@snap1
zpool list
sleep 1

echo "=== ZFS Phase 2: Post-snapshot writes (5s) ==="
blktrace -d /dev/vdc -o zfs_p2 -D /tmp/trace -w 10 &
BT=$!
sleep 1

fio --name=randwrite --filename=/testpool/testfile \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=5 --output=/tmp/trace/fio_zfs_p2.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true

echo "=== ZFS: Final ==="
zpool list
echo "=== ZFS Done ==="
