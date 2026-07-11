#!/bin/bash
set -eu

echo "=== LINEAR: Phase 1 - normal writes (5s) ==="
blktrace -d /dev/vdc -o linear_p1 -D /tmp/trace -w 10 &
BT=$!
sleep 1

fio --name=randwrite --filename=/dev/vg_linear/lv_test \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=5 --output=/tmp/trace/fio_linear_p1.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true
sleep 1

echo "=== LINEAR: Taking snapshot ==="
lvcreate -s -L 1G -n snap_test vg_linear/lv_test
udevadm settle
sleep 1

echo "=== LINEAR: Phase 2 - COW writes (5s) ==="
blktrace -d /dev/vdc -o linear_p2 -D /tmp/trace -w 10 &
BT=$!
sleep 1

fio --name=randwrite --filename=/dev/vg_linear/lv_test \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=5 --output=/tmp/trace/fio_linear_p2.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true

echo "=== LINEAR: Done ==="
