#!/bin/sh
echo "Starting module called module-01" >> /tmp/progress.log

touch /etc/sudoers.d/rhel_sudoers
echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
cp -a /root/.ssh/* /home/rhel/.ssh/.
chown -R rhel:rhel /home/rhel/.ssh
