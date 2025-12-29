# sd-card-check
identify fake sd-cards and USB-Sticks

I have been struggling for a while already with some sd-cards that made my raspi and odroid crash, or web-cams that could not record any more due to corrupt sd-cards.
Until then, my test of new cards and usb keys was limited to reformatting them to exFAT, helping me to eliminate obvious fake devices:
# sudo diskutil eraseDisk ExFAT "sd_512" /dev/disk4 

I am working on a macbook and the KO indicator was a failed mount after the creation of the new partition, which seemed to work fine except for that second last line:
# Started erase on disk4
# Unmounting disk
# Creating the partition map
# ...
# Mounting disk
# Could not mount disk4s2 after erase
# Finished erase on disk4

I was playing with f3write and f3read for in-depth testing but it was simply far too time consuming for larger devices.
For that reason, I developed (with some help by Gemini) a script to test the announced storage space at any given location by writing a data sample via dd and reading it back, which works fine for any real capacity but fails for non-existing space because the fake devices start overwriting existing data.
The script shows also the total size of the card/key in GiB, which is usually lower than the announced size in GB (GB/1.024=GiB)
For fake devices the script shows an unrealistic value (GiB=GB)

WARNING: the script overwrites potentially existing data and should only be used on empty cards/keys or after having made a backup copy.
NOTE: the script is provided as is, without any guarantees and at your own risk

For indentified fake cards and a reasonable real size, you can make these cards/keys usuable for their real capacity, by creating a partition for that real capacity and reserving the rest as availbe space, eg.
# diskutil partitionDisk /dev/disk4 ExFAT "SD_8GB" 8G Free\ Space "REST" R

