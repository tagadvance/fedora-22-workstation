#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "Thi script must be run as root!" 1>&2
  exit 1
fi

# disable selinux
setenforce 0
cat <<EOF > /etc/selinux/config
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
EOF

# switch back to iptables
dnf install iptables-services -y
systemctl disable firewalld
systemctl enable iptables
systemctl start iptables

# reduce swappiness
cat /proc/sys/vm/swappiness
echo "vm.swappiness=0" > /etc/sysctl.d/vm.swappiness.conf

# mount /tmp on tmpfs
echo "tmpfs /tmp tmpfs defaults,size=1G,mode=1777 0 0" >> /etc/fstab

dnf clean all
dnf update -y
# for virtualbox guest additions
dnf groupinstall "Development Tools" -y
dnf install kernel-devel dkms -y
# misc
dnf install nano htop screen -y

# google chrome
cat <<EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF
dnf update -y
dnf install google-chrome-stable -y

# java development
dnf install java-1.8.0-openjdk -y
cd /tmp
ECLIPSE=eclipse-jee-mars-R-linux-gtk-x86_64.tar.gz
USER=$(logname)
HOME=$(eval echo ~$USER)
wget --output-document=$ECLIPSE http://ftp.ussg.iu.edu/eclipse/technology/epp/downloads/release/mars/R/$ECLIPSE
tar -zxvf $ECLIPSE
chown -R $USER:$USER eclipse
mv /tmp/eclipse $HOME/
