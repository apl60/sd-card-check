# sd-card-check
identify fake sd-cards and USB-Sticks

USAGE:
sudo ./faketest.sh /dev/rdisk4      
Usage: sudo ./faketest.sh <device> <size_in_gb> <single test size>
Example: sudo ./faketest.sh /dev/rdisk5 64 60


I have been struggling for a while already with some sd-cards that made my raspi and odroid crash, or web-cams that could not record any more due to corrupt sd-cards.
Until then, my test of new cards and usb keys was limited to reformatting them to exFAT, helping me to eliminate obvious fake devices:

I am working on a macbook and the KO indicator was a failed mount after the creation of the new partition, which seemed to work fine except for that second last line:
% sudo diskutil eraseDisk ExFAT "sd_512" /dev/disk4 
Started erase on disk4
Unmounting disk
Creating the partition map
 ...
Mounting disk
Could not mount disk4s2 after erase
Finished erase on disk4

I was playing with f3write and f3read for in-depth testing but it was simply far too time consuming for larger devices.
For that reason, I developed (with some help by Gemini) a script to test the announced storage space at any given location by writing a data sample via dd and reading it back, which works fine for any real capacity but fails for non-existing space because the fake devices start overwriting existing data.
The script shows also the total size of the card/key in GiB, which is usually lower than the announced size in GB (GB/1.024=GiB)
For fake devices the script shows an unrealistic value (GiB=GB)

SAMPLE OUTPUT:
% sudo ./faketest.sh /dev/rdisk4 32 30
Password:
--- FAKE CHECK STARTED FOR /dev/rdisk4 (32 GB) ---
Test 30 GB data point @29995 MB... 
testblock.bin: MARKER-30-GB-POINT-1767022795
dd if=testblock.bin of=/dev/rdisk4 bs=1m seek=29995 count=1
DD_STATS=$(sudo dd if=testblock.bin of=/dev/rdisk4 bs=1m seek=29995 count=1 conv=sync 2>&1 >/dev/null)
Speed: 37.78 MB/s
1+0 records in
1+0 records out
1048576 bytes transferred in 0.181343 secs (5782277 bytes/sec)
OK
Disk Size (diskutil): 30728 MiB
--- TEST FINISHED ---

SAMPLE RESULTS COMMENTED:
This seems to be an ok sd-card, 32GB with a real capacity of 30 GiB -> test test finishes ok for a test size of 30 (3rd parameter)
In case of errors, the test should be lauched without the 3rd parameter, showing how far the test work OK for the real capacity. Pls see options below for making the real capacity usable without risking data corruption.
NOTE: if the total disk size indicated at the end of the execution matches exactly the indicated size, the controller is most likely modified to show a wrong capacity and any test for higher capacities will fail.

WARNING: the script overwrites potentially existing data and should only be used on empty cards/keys or after having made a backup copy.
NOTE: the script is provided as is, without any guarantees and at your own risk

For indentified fake cards and a reasonable real size, you can make these cards/keys usuable for their real capacity, by creating a partition for that real capacity and reserving the rest as availbe space, eg.

% diskutil partitionDisk /dev/disk4 ExFAT "SD_8GB" 8G Free\ Space "REST" R

