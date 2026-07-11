#!/bin/bash
set -eu

FS=$1       # zfs or btrfs
DEV=$2      # /dev/vdc or /dev/vdd
FILE=$3     # /testpool/testfile or /mnt/btrfs/testfile
TRACE_PFX=$4  # zfs or btrfs

# Btrfs needs fallocate=none to avoid preallocation
EXTRA=""
if [ "$FS" = "btrfs" ]; then
    EXTRA="--fallocate=none --create_on_open=1"
fi

echo "=== ${FS}: Phase 1 - Initial writes (10s) ==="
blktrace -d $DEV -o ${TRACE_PFX}_p1 -D /tmp/trace -w 15 &
BT=$!; sleep 1

fio --name=rw --filename=$FILE \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    $EXTRA --randseed=12345 --numjobs=1 \
    --time_based --runtime=10 --output=/tmp/trace/fio_${TRACE_PFX}_p1.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true; sleep 1

echo "=== ${FS}: Taking snapshot 1 ==="
if [ "$FS" = "zfs" ]; then
    zfs snapshot testpool@snap1
else
    btrfs subvolume snapshot -r /mnt/btrfs /mnt/btrfs/.snap1
    sync
fi
sleep 1

echo "=== ${FS}: Phase 2 - Post-snap1 writes (30s) ==="
blktrace -d $DEV -o ${TRACE_PFX}_p2 -D /tmp/trace -w 35 &
BT=$!; sleep 1

fio --name=rw --filename=$FILE \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    $EXTRA --randseed=67890 --numjobs=1 \
    --time_based --runtime=30 --output=/tmp/trace/fio_${TRACE_PFX}_p2.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true; sleep 1

echo "=== ${FS}: Taking snapshot 2 ==="
if [ "$FS" = "zfs" ]; then
    zfs snapshot testpool@snap2
else
    btrfs subvolume snapshot -r /mnt/btrfs /mnt/btrfs/.snap2
    sync
fi
sleep 1

echo "=== ${FS}: Phase 3 - Post-snap2 writes (10s) ==="
blktrace -d $DEV -o ${TRACE_PFX}_p3 -D /tmp/trace -w 15 &
BT=$!; sleep 1

fio --name=rw --filename=$FILE \
    --rw=randwrite --bs=4k --size=512M \
    --iodepth=1 --direct=1 --ioengine=libaio \
    $EXTRA --randseed=11111 --numjobs=1 \
    --time_based --runtime=10 --output=/tmp/trace/fio_${TRACE_PFX}_p3.log

kill $BT 2>/dev/null; wait $BT 2>/dev/null || true

echo "=== ${FS}: Done ==="
