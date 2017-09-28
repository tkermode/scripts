# leave ssh disabled at first, do this from the console
# vi /etc/ssh/sshd_config
# service sshd restart
# edit sshd_config to enable whatever ports and options are needed

# install iptables and disable firewalld
yum install iptables
systemctl disable firewalld
systemctl stop firewalld
yum install wget
yum install ipset

# wget the update_firewall_centos.sh from somewhere
# uncomment the get zones commands in the firewall script
# then run the script to update iptables
# consider putting it in cron to run on reboot, else use iptables-persistent or similar

# next line assumes you have the script already local
./update_firewall_centos.sh

# install other repos which are useful, and the keys needed to use them
yum install epel-release
rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm

# install X Windows and a GUI DE
yum groupinstall "X Window system"
yum groupinstall "MATE Desktop"
# (or GNOME or whatever instead of MATE if desired)

# enable the GUI to start automatically
systemctl isolate graphical.target
systemctl set-default graphical.target

# install some other useful stuff, some of which are in the added repos above
yum install gnome-disk-utility
yum install tigervnc-server
yum install tigervnc-server-module
yum install xrdp
yum install rdesktop

# enable rdp and set the selinux contexts so it works
# might also have to do some xrdp config file edits
systemctl start xrdp.service
systemctl enable xrdp.service
chcon --type=bin_t /usr/sbin/xrdp
chcon --type=bin_t /usr/sbin/xrdp-sesman
