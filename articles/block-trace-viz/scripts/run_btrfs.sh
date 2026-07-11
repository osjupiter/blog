#!/bin/bash
set -eu

echo "=== BTRFS: Normal writes (10s) ==="
blktrace -d /dev/vdd -o btrfs -D /tmp/trace -w 15 &
BT=$!
sleep 1

fio --name=randwrite --filename=/mnt/btrfs/testfile \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --fallocate=none --create_on_open=1 --randseed=12345 --numjobs=1 \
    --time_based --runtime=10 --output=/tmp/trace/fio_btrfs.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true
echo "=== BTRFS: Done ==="
