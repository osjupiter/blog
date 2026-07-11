#!/bin/bash
set -eu

echo "=== THIN: Phase 1 - fresh allocation (5s) ==="
blktrace -d /dev/vdd -o thin_p1 -D /tmp/trace -w 10 &
BT=$!
sleep 1

fio --name=randwrite --filename=/dev/vg_thin/lv_test \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=5 --output=/tmp/trace/fio_thin_p1.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true
sleep 1

echo "=== THIN: Phase 2 - overwrite mapped (5s) ==="
blktrace -d /dev/vdd -o thin_p2 -D /tmp/trace -w 10 &
BT=$!
sleep 1

fio --name=randwrite --filename=/dev/vg_thin/lv_test \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=5 --output=/tmp/trace/fio_thin_p2.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true
sleep 1

echo "=== THIN: Taking snapshot ==="
lvcreate -s -n snap_test vg_thin/lv_test
udevadm settle
sleep 1

echo "=== THIN: Phase 3 - ROW writes (5s) ==="
blktrace -d /dev/vdd -o thin_p3 -D /tmp/trace -w 10 &
BT=$!
sleep 1

fio --name=randwrite --filename=/dev/vg_thin/lv_test \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    --randseed=12345 --numjobs=1 \
    --time_based --runtime=5 --output=/tmp/trace/fio_thin_p3.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true

echo "=== THIN: Done ==="
