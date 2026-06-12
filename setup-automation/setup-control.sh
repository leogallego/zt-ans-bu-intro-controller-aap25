#!/bin/bash

# Register with Satellite for RHEL repos (clean stale certs from base image)
subscription-manager clean
curl -k -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}

systemctl stop systemd-tmpfiles-setup.service
systemctl disable systemd-tmpfiles-setup.service


nmcli connection add type ethernet con-name enp2s0 ifname enp2s0 ipv4.addresses 192.168.1.10/24 ipv4.method manual connection.autoconnect yes
nmcli connection up enp2s0
echo "192.168.1.10 control.lab control controller" >> /etc/hosts

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
    sudo -u rhel ssh-keygen -t rsa -b 4096 -m PEM -C "rhel@$(hostname)" -f /home/rhel/.ssh/id_rsa -N "" -q
    sudo -u rhel chmod 600 /home/rhel/.ssh/id_rsa*
    
    if [ -f "$RHEL_PRIVATE_KEY" ]; then
        echo "SSH key created successfully for rhel user"
    else
        echo "Error: Failed to create SSH key for rhel user"
    fi
fi

# ## ansible home
mkdir /home/$USER/ansible
## ansible-files dir
mkdir /home/$USER/ansible-files

# ## ansible.cfg
echo "[defaults]" > /home/$USER/.ansible.cfg
echo "inventory = /home/$USER/ansible-files/hosts" >> /home/$USER/.ansible.cfg
echo "host_key_checking = False" >> /home/$USER/.ansible.cfg

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
EOL
'

# ## copy navigator settings
su - $USER -c 'cp /home/$USER/ansible-navigator.yml /home/$USER/.ansible-navigator.yml'
su - $USER -c 'cp /home/$USER/ansible-navigator.yml /home/$USER/ansible-files/ansible-navigator.yml'


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

# ## Controller as Code (CaC) setup
# Create venv with ansible-core 2.16.z (matches ee-supported-rhel9)
# CaC files are copied to /tmp/controller-as-code/ by setup-automation/main.yml
dnf install -y python3-pip python3.11 python3.11-pip
python3.11 -m venv /tmp/cac-venv
/tmp/cac-venv/bin/pip install --quiet --upgrade pip
/tmp/cac-venv/bin/pip install --quiet "ansible-core~=2.16.0"
/tmp/cac-venv/bin/ansible-galaxy collection install git+https://github.com/ansible/ansible.platform.git,2.5.20251114
/tmp/cac-venv/bin/ansible-galaxy collection install infra.aap_configuration:==4.6.0
