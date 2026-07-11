#!/bin/bash
set -eu

echo "=== Btrfs Phase 1: Normal writes (5s) ==="
blktrace -d /dev/vdd -o btrfs_p1 -D /tmp/trace -w 10 &
BT=$!
sleep 1

fio --name=randwrite --filename=/mnt/btrfs/testfile \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=5 --output=/tmp/trace/fio_btrfs_p1.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true
sleep 1

echo "=== Btrfs: Taking snapshot ==="
btrfs subvolume snapshot -r /mnt/btrfs /mnt/btrfs/snap1
sync
sleep 1

echo "=== Btrfs Phase 2: Post-snapshot writes (5s) ==="
blktrace -d /dev/vdd -o btrfs_p2 -D /tmp/trace -w 10 &
BT=$!
sleep 1

fio --name=randwrite --filename=/mnt/btrfs/testfile \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=5 --output=/tmp/trace/fio_btrfs_p2.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true

echo "=== Btrfs Done ==="
