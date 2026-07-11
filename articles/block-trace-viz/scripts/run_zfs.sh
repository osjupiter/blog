#!/bin/bash
set -eu

echo "=== ZFS: Normal writes (10s) ==="
blktrace -d /dev/vdc -o zfs -D /tmp/trace -w 15 &
BT=$!
sleep 1

fio --name=randwrite --filename=/testpool/testfile \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=10 --output=/tmp/trace/fio_zfs.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true
echo "=== ZFS: Done ==="
