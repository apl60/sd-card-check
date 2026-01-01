#!/bin/bash   
# 2025-12-20 - Andreas Pagel - email:faketest.sh@pagel.info
# Nutzung: sudo ./fakecheck.sh /dev/rdiskX 2000
# (Parameter 1: Device, Parameter 2: Angegebene Größe in GB, optionally Parameter 3: single test with give size)

DEVICE=$1
SIZE_GB=$2

if [ -z "$DEVICE" ] || [ -z "$SIZE_GB" ]; then
    echo "Usage: sudo $0 <device> <size_in_gb> <single test size>"
    echo "Example: sudo $0 /dev/rdisk5 64 60"
    exit 1
fi

# Testpunkte in GB (du kannst die Liste erweitern)
if [ -z "$3" ]; then
   TEST_POINTS=(1 4 8 16 32 64 128 256 512 1000 2000)
else
   TEST_POINTS=($3)
fi
echo "--- FAKE CHECK STARTED FOR $DEVICE ($SIZE_GB GB) ---"

for GB in "${TEST_POINTS[@]}"; do
    # finish test if test point bigger than provided size
    if [ $SIZE_GB -eq 0 ]; then break; fi
    if [ $GB -gt $SIZE_GB ]; then 
      GB=$SIZE_GB
      SIZE_GB=0
    fi

    # use safe seek value (5MB before target size)
    SAFE_SEEK=$((GB * 1000-5)) 

    echo "Test $GB GB data point @$SAFE_SEEK MB... "

    # create unique text pattern for test of current data point
    PATTERN="MARKER-$GB-GB-POINT-$(date +%s)"
    echo $PATTERN > pattern.txt

        if [[ "$3" -ne "" ]]; then
          echo -n "testblock.bin: "
          cat pattern.txt
          echo "dd if=testblock.bin of="$DEVICE" bs=1m seek=$SAFE_SEEK count=1"
          echo "DD_STATS=\$(sudo dd if=testblock.bin of=$DEVICE bs=1m seek=$SAFE_SEEK count=1 conv=sync 2>&1 >/dev/null)"
        fi


    dd if=/dev/zero bs=1m count=1 >> pattern.txt 2>/dev/null
    dd if=pattern.txt of=testblock.bin bs=1m count=1 2>/dev/null
    
    # write pattern to 1MB block (fill rest with nulls)
    diskutil unmountDisk "${DEVICE/rdisk/disk}" > /dev/null # dd works only if device unmounted
    DD_STATS=$(sudo dd if=testblock.bin of="$DEVICE" bs=1m seek=$SAFE_SEEK count=1 conv=sync 2>&1 >/dev/null)
    # extract write speed
    BYTES_PER_SEC=$(echo "$DD_STATS" | grep -oE "\([0-9]+ bytes/sec\)" | tr -d '() bytes/sec')

    if [ ! -z "$BYTES_PER_SEC" ]; then
      MB_SEC=$(awk "BEGIN {printf \"%.2f\", $BYTES_PER_SEC / 1000000}")
      SPEED_INFO="Speed: $MB_SEC MB/s"
    else
      SPEED_INFO="Speed: N/A"
    fi
    echo $SPEED_INFO
    sleep 1    
    if [ $? -ne 0 ]; then
        echo "ERROR:  dd write failed (Hardware I/O Error)!"
        #continue
        echo "dd if=testblock.bin of="$DEVICE" bs=1m seek=$SAFE_SEEK count=1 conv=sync"
        exit
    fi

    # macOS Cache flashen
    diskutil unmountDisk "${DEVICE}" > /dev/null

    # read back written pattern
    RESULT=$(dd if="$DEVICE" bs=1m skip=$SAFE_SEEK count=1 | strings | grep "MARKER-$GB-GB")

    if [[ "$RESULT" == *"$PATTERN"* ]]; then
        echo "OK"
        if [[ "$3" -eq "" ]]; then
          echo $RESULT
        fi
    else
        #echo "1. test unsucessful:"
        # 2. trial:
        diskutil unmountDisk "${DEVICE}" > /dev/null
        sleep 1
        dd if=testblock.bin of="$DEVICE" bs=1m seek=$SAFE_SEEK count=1 conv=sync >/dev/null 2>/dev/null
        sleep 1
        RESULT=$(dd if="$DEVICE" bs=1m skip=$SAFE_SEEK count=1 | strings | grep "MARKER-$GB-GB")
        echo "dd if=$DEVICE bs=1m skip=$SAFE_SEEK count=1 | hexdump -C | head -5"
        dd if="$DEVICE" bs=1m skip=$SAFE_SEEK count=1 | hexdump -C | head -5
        if [[ "$RESULT" != *"$PATTERN"* ]]; then
          echo "DEFEKT/FAKE! (data overwritten or writing into non-existing storage)"
        fi
    fi
done
# read exact byte size of device
ACTUAL_SIZE_BYTES=$(diskutil info $DEVICE | grep "Disk Size" | awk '{print $5}' | tr -d '()')
ACTUAL_SIZE_MB=$((ACTUAL_SIZE_BYTES / 1000 / 1000)) # Dezimale MB
ACTUAL_SIZE_MiB=$((ACTUAL_SIZE_BYTES / 1024 / 1024)) # Dezimale MB
#echo $ACTUAL_SIZE_BYTES
echo "Disk Size (diskutil): $ACTUAL_SIZE_MiB MiB"
echo "--- TEST FINISHED ---"
