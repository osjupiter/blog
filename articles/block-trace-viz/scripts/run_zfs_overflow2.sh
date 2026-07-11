#!/bin/bash
set -eu

echo "=== Continuing writes until ENOSPC (60s max) ==="
echo "=== Current pool: ==="
zpool list

blktrace -d /dev/vdc -o zfs_p3 -D /tmp/trace -w 70 &
BT=$!
sleep 1

fio --name=randwrite --filename=/testpool/testfile \
    --rw=randwrite --bs=4k --size=4G \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=99999 --numjobs=1 \
    --time_based --runtime=60 --output=/tmp/trace/fio_zfs_p3.log 2>&1 || true

echo "=== fio exit code: $? ==="

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true

echo "=== Final pool status: ==="
zpool list
zpool status testpool
zfs list -t all
dmesg | tail -20
echo "=== Done ==="
