# !/bin/bash
# update_firewall.sh

# Update firewall by flushing all rules and rebuilding them.
# This script is based on the idea of whitelisting specific subnets and/or IP addresses,
# then blacklisting specific IP addresses based on hacking attempts, similar to fail2ban but
# more simply. It is designed to work in conjunction with the 'update_blacklist.sh' script,
# which creates and updates a blacklist based on bad login attempts logged in btmp.
# The goal is to whitelist subnets by country, instead of blacklisting. Obviously, this is
# less useful for a general Web site than for semi-private sites or other kinds of host connectivity.

# Script assumptions:
# 1. Script will be run as root, typically as a crontab on reboot or at set intervals
# 2. iptables, ipset, and wget are installed
# 3. Distro is based on Debian or Fedora (Ubuntu, Mint, CentOS, etc.)
# 4. Script is rough for my purposes, not generalised; should be rewritten for more general use
#    especially to allow easier population of network interface and allowed subnets.
# 5. Designed for one host - allows all incoming ports for the whitelisted subnets; assumes your
#    main firewall is blocking/allowing specific ports.

# Disable Internet access while we rebuild the firewall to prevent attacks during the ruleset rebuilding.
# Replace 192.168.1.1 with your gateway address, if different.
/sbin/route del default gw 192.168.1.1

# Flush the current firewall rules and ipsets, if any
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
ipset -F
ipset -X

# Allow existing connections to continue
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Rule to allow DHCP requests to pass through iptables to the DHCP server
# This assumes interface is enp2s0, should be rewritten to dynamically grab the correct interface
iptables -A INPUT -i enp2s0 -p udp --dport 67:68 -j ACCEPT

# Accept everything from the 192.168.1.0 network for INPUT and FORWARD chains
# Assumes your local subnet is 192.168.1.0/24
iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT

# Accept everything from certain other trusted networks
# replace this with whatever subnets and/or IPs are trusted for your use case
iptables -A INPUT -s 129.121.3.174/32 -j ACCEPT

# Certain trusted subnets - some examples are shown, use appropriate for your use case
iptables -A INPUT -s 148.108.0.0/16 -j ACCEPT
iptables -A INPUT -s 205.132.72.0/22 -j ACCEPT
iptables -A INPUT -s 205.132.76.0/24 -j ACCEPT


# Allow outgoing connections from this host
iptables -P OUTPUT ACCEPT

# Local loopback rules
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT


# ipset stuff

# get new zone files
mkdir -p /root/zones # make sure the target dir exists locally

# Here we will get whatever country zone files are appropriate to our use case.
# Be careful, could overwrite good files if the ipdeny site goes down!
# leave them commented out and run manually for now!

# you'd also have to re-enable Internet using /sbin/route add default gw 192.168.1.1
# wget -O /root/zones/ch.zone http://www.ipdeny.com/ipblocks/data/countries/ch.zone
# wget -O /root/zones/de.zone http://www.ipdeny.com/ipblocks/data/countries/de.zone
# wget -O /root/zones/us.zone http://www.ipdeny.com/ipblocks/data/countries/us.zone

# destroy and rebuild ipset whitelists
ipset destroy whitelist_ch
ipset destroy whitelist_de
ipset destroy whitelist_us1
ipset destroy whitelist_us2
ipset destroy blacklist_custom
ipset -N whitelist_ch nethash
ipset -N whitelist_de nethash
ipset -N whitelist_us1 nethash
ipset -N whitelist_us2 nethash
ipset -N blacklist_custom nethash
for IP in $(cat /root/zones/ch.zone);do ipset -A whitelist_ch $IP;done;
for IP in $(cat /root/zones/de.zone);do ipset -A whitelist_de $IP;done;
for IP in $(cat /root/zones/blacklist.zone);do ipset -A blacklist_custom $IP;done;

# split up the us.zone file so it's not too big for the hash elements limit
# the limit is 65,536 elements
let a=`cat /root/zones/us.zone |wc -l` # count the number of lines in the us.zone file
let b=$a/2  # divide that number by 2 (I'm being lazy).
cd /root/zones/
split -l $b /root/zones/us.zone uszone # split it into two files
for IP in $(cat /root/zones/uszoneaa);do ipset -A whitelist_us1 $IP;done;
for IP in $(cat /root/zones/uszoneab);do ipset -A whitelist_us2 $IP;done;

# optional, you could save your ipsets, destroy them, then restore, but why?
# but it might be useful...
# ipset save whitelist_ch -file /root/zones/whitelist_ch.save
# ipset save whitelist_de -file /root/zones/whitelist_de.save
# ipset save whitelist_us -file /root/zones/whitelist_us.save
# ipset destroy whitelist_ch
# ipset destroy whitelist_de
# ipset destroy whitelist_us
# ipset restore -file /root/zones/whitelist_ch.save
# ipset restore -file /root/zones/whitelist_de.save
# ipset restore -file /root/zones/whitelist_us.save

# Set up the ipset country whitelist rules in iptables
iptables -N countryfilter
iptables -A INPUT -m state --state NEW -j countryfilter
iptables -A countryfilter -m set --match-set whitelist_ch src -j RETURN
iptables -A countryfilter -m set --match-set whitelist_de src -j RETURN
iptables -A countryfilter -m set --match-set whitelist_us1 src -j RETURN
iptables -A countryfilter -m set --match-set whitelist_us2 src -j RETURN
iptables -A INPUT -m set --match-set blacklist_custom src -j REJECT
iptables -A FORWARD -m set --match-set blacklist_custom src -j REJECT
iptables -A countryfilter -j REJECT


# re-enable Internet access
/sbin/route add default gw 192.168.1.1

# clear and list the rules
clear
iptables -L
