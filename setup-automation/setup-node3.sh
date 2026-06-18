#!/bin/bash


curl -k -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm

subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}

touch /etc/sudoers.d/rhel_sudoers
echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
cp -a /root/.ssh/* /home/rhel/.ssh/.
chown -R rhel:rhel /home/rhel/.ssh

## clean repo metadata and refresh
dnf config-manager --disable google*
dnf clean all
dnf config-manager --enable rhui-rhel-9-for-x86_64-baseos-rhui-rpms
dnf config-manager --enable rhui-rhel-9-for-x86_64-appstream-rhui-rpms
dnf makecache

# stop web server
systemctl stop nginx

# make Dan Walsh weep: https://stopdisablingselinux.com/
setenforce 0
