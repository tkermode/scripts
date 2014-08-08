#!/usr/bin/env bash 

# Periodically check a directory which is being populated with data
# to see how much is left, assuming that you know the amount being
# transferred. It shows the disk space used in human-readable format,
# then in raw bytes.

# Planned changes: Prompt for input of directory to check and how long to sleep.
script to allow input of directory


while true;
do
du -hs ~/Music/;
du -s ~/Music/;
sleep 20;
done;
