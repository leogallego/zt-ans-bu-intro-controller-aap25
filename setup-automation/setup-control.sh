#!/bin/bash

systemctl stop systemd-tmpfiles-setup.service
systemctl disable systemd-tmpfiles-setup.service


# Install collection(s)


nmcli connection add type ethernet con-name enp2s0 ifname enp2s0 ipv4.addresses 192.168.1.10/24 ipv4.method manual connection.autoconnect yes
nmcli connection up enp2s0
echo "192.168.1.10 control.lab control controller" >> /etc/hosts

su - rhel -c 'pip install ansible-navigator'

echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
chmod 440 /etc/sudoers.d/rhel_sudoers
echo "Checking SSH keys for rhel user..."

RHEL_SSH_DIR="/home/rhel/.ssh"
RHEL_PRIVATE_KEY="$RHEL_SSH_DIR/id_rsa"
RHEL_PUBLIC_KEY="$RHEL_SSH_DIR/id_rsa.pub"

if [ -f "$RHEL_PRIVATE_KEY" ]; then
    echo "SSH key already exists for rhel user: $RHEL_PRIVATE_KEY"
else
    echo "Creating SSH key for rhel user..."
    sudo -u rhel mkdir -p /home/rhel/.ssh
    sudo -u rhel chmod 700 /home/rhel/.ssh
    sudo -u rhel ssh-keygen -t rsa -b 4096 -C "rhel@$(hostname)" -f /home/rhel/.ssh/id_rsa -N "" -q
    sudo -u rhel chmod 600 /home/rhel/.ssh/id_rsa*
    
    if [ -f "$RHEL_PRIVATE_KEY" ]; then
        echo "SSH key created successfully for rhel user"
    else
        echo "Error: Failed to create SSH key for rhel user"
    fi
fi

# # ## setup rhel user
touch /etc/sudoers.d/rhel_sudoers
echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
# # cp -a /root/.ssh/* /home/$USER/.ssh/.
# # chown -R rhel:rhel /home/$USER/.ssh
# export CONTROLLER_USERNAME=admin
# export CONTROLLER_PASSWORD=ansible123!
# export CONTROLLER_VERIFY_SSL=false

# ## ansible home
mkdir /home/$USER/ansible
## ansible-files dir
mkdir /home/$USER/ansible-files

# ## ansible.cfg
echo "[defaults]" > /home/$USER/.ansible.cfg
echo "inventory = /home/$USER/ansible-files/hosts" >> /home/$USER/.ansible.cfg
echo "host_key_checking = False" >> /home/$USER/.ansible.cfg

# ## chown and chmod all files in rhel user home
# chown -R rhel:rhel /home/$USER/ansible
# chmod 777 /home/$USER/ansible
# #touch /home/rhel/ansible-files/hosts
# chown -R rhel:rhel /home/$USER/ansible-files

# ## git setup
git config --global user.email "rhel@example.com"
git config --global user.name "Red Hat"
su - $USER -c 'git config --global user.email "rhel@example.com"'
su - $USER -c 'git config --global user.name "Red Hat"'


# ## set ansible-navigator default settings
# ## for the EE to work we need to pass env variables
# ## TODO: controller_host doesnt resolve with control and 127.0.0.1
# ## is interpreted within the EE
su - $USER -c 'cat >/home/$USER/ansible-navigator.yml <<EOL
---
ansible-navigator:
  ansible:
    inventory:
      entries:
      - /home/rhel/ansible-files/hosts
  execution-environment:
    container-engine: podman
    container-options:
      - "--net=host"
    enabled: true
    image: registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9
    pull:
      policy: missing
    environment-variables:
      pass:
        - CONTROLLER_USERNAME
        - CONTROLLER_PASSWORD
        - CONTROLLER_VERIFY_SSL
      set:
        CONTROLLER_HOST: localhost
  logging:
    level: debug
  mode: stdout
  playbook-artifact:
    save-as: /home/rhel/{playbook_name}-artifact-{time_stamp}.json

# EOL
# cat /home/$USER/ansible-navigator.yml'

# ## copy navigator settings
su - $USER -c 'cp /home/$USER/ansible-navigator.yml /home/$USER/.ansible-navigator.yml'
su - $USER -c 'cp /home/$USER/ansible-navigator.yml /home/$USER/ansible-files/ansible-navigator.yml'


git clone https://github.com/ansible-tmm/controller-101.git /tmp/controller-101-2024


# ## set inventory hosts for commandline ansible
su - $USER -c 'cat >/home/$USER/ansible-files/hosts <<EOL
[web]
node1
node2

[database]
node3

[controller]
control

EOL
cat /home/$USER/ansible-files/hosts'
## end inventory hosts

# ## chown and chmod all files in rhel user home
chown -R rhel:rhel /home/rhel/ansible
chmod 777 /home/rhel/ansible
#touch /home/rhel/ansible-files/hosts
chown -R rhel:rhel /home/rhel/ansible-files

## install ansible-navigator
dnf install -y python3-pip 
su - $USER -c 'python3 -m pip install ansible-navigator --user'
echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/$USER/.profile
echo 'export PATH=$HOME/.local/bin:$PATH' >> /etc/profile

# ## Controller as Code (CaC) setup
# Install the infra.aap_configuration collection for CaC playbooks
# CaC files are copied to /tmp/controller-as-code/ by setup-automation/main.yml
ansible-galaxy collection install infra.aap_configuration
