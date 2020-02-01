#!/bin/bash
# update_blacklist.sh
# Update a blacklist of bad IPs by combining the existing blacklist and the current list of bad IPs from btmp

# Concatenate the output of unique IPs from the previously saved blacklist (if any) and the current btmp contents.

# For whatever stupid reason, btmp is binary, and if you simply cat it, the contents are still not
# text...so we have to do some awk magic. Plus we want to look for just good IP addresses and not
# hostnames, so that we can add the IPs to a blacklist and later use ipset to hash them

# This will cat btmp, awk the output to find just IPs, then cat it with the previously saved blacklist zone file;
# it sorts the results of the concatenation, finding unique addresses only, then dumps the whole mess back into 
# the same blacklist.zone file name. The next time that update_firewall.sh is run, typically on the next reboot,
# the blacklist.zone file will be used to populate an ipset.

# backup the zone file, assuming that it exists
mkdir -p /root/zones # make the dir
touch /root/zones/blacklist.zone # make the file if it doesn't already exist
touch /root/zones/blacklist.save # make the file if it doesn't already exist
mv /root/zones/blacklist.zone /root/zones/blacklist.save # copy the old blacklist to a backup copy

# cat btmp and blacklist.zone
cat <(lastb |awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}') /root/zones/blacklist.save |sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n |uniq > /root/zones/blacklist.zone

# remove leading space
sed -i '/./,$!d' /root/zones/blacklist.zone # assumes a version of sed which allows inline editing

# Note that it doesn't matter much when you rotate or null out btmp, because the script will always preserve
# whatever IPs existed in the blacklist prior to running the script again.
