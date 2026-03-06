#!/bin/bash

systemctl stop systemd-tmpfiles-setup.service
systemctl disable systemd-tmpfiles-setup.service


# Install collection(s)
ansible-galaxy collection install community.general

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
ansible-galaxy collection install infra.aap_configuration

# Create the CaC directory structure on the control node
CAC_DIR="/tmp/controller-as-code"
mkdir -p "${CAC_DIR}/configs/module-"{03,04,05,06,07,08,09,10}

# Ansible config for CaC directory (ensures collection is found regardless of user)
cat > "${CAC_DIR}/ansible.cfg" << 'ENDOFFILE'
[defaults]
host_key_checking = false
collections_paths = /tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections:/root/.ansible/collections
ENDOFFILE

# Auth config
cat > "${CAC_DIR}/configs/auth.yml" << 'ENDOFFILE'
---
aap_hostname: "https://localhost"
aap_username: admin
aap_password: ansible123!
aap_validate_certs: false
ENDOFFILE

# Module 03: Inventory, hosts, groups
cat > "${CAC_DIR}/configs/module-03/controller_objects.yml" << 'ENDOFFILE'
---
controller_inventories_module03:
  - name: Lab-Inventory
    organization: Default
controller_hosts_module03:
  - name: node1
    inventory: Lab-Inventory
    state: present
  - name: node2
    inventory: Lab-Inventory
    state: present
controller_groups_module03:
  - name: web
    inventory: Lab-Inventory
    hosts:
      - node1
      - node2
ENDOFFILE

# Module 04: Apache playbooks project
cat > "${CAC_DIR}/configs/module-04/controller_objects.yml" << 'ENDOFFILE'
---
controller_projects_module04:
  - name: Apache playbooks
    organization: Default
    state: present
    scm_type: git
    scm_url: https://github.com/ansible-tmm/instruqt-wyfp.git
    wait: true
ENDOFFILE

# Module 05: Credentials
cat > "${CAC_DIR}/configs/module-05/controller_objects.yml" << 'ENDOFFILE'
---
controller_credentials_module05:
  - name: lab-credentials
    credential_type: Machine
    organization: Default
    inputs:
      username: rhel
      password: ansible123!
      ssh_key_data: "{{ lookup('file', '/home/rhel/.ssh/id_rsa') }}"
ENDOFFILE

# Module 06: Install Apache job template
cat > "${CAC_DIR}/configs/module-06/controller_objects.yml" << 'ENDOFFILE'
---
controller_templates_module06:
  - name: Install Apache
    organization: Default
    state: present
    inventory: Lab-Inventory
    become_enabled: true
    playbook: apache.yml
    project: Apache playbooks
    credential: lab-credentials
ENDOFFILE

# Module 07: Additional playbooks project
cat > "${CAC_DIR}/configs/module-07/controller_objects.yml" << 'ENDOFFILE'
---
controller_projects_module07:
  - name: Additional playbooks
    organization: Default
    state: present
    scm_type: git
    scm_url: https://github.com/ansible-tmm/instruqt-wyfp-additional.git
    wait: true
ENDOFFILE

# Module 08: node3, database group, Extended services and Set motd templates
cat > "${CAC_DIR}/configs/module-08/controller_objects.yml" << 'ENDOFFILE'
---
controller_hosts_module08:
  - name: node3
    inventory: Lab-Inventory
    state: present
controller_groups_module08:
  - name: database
    inventory: Lab-Inventory
    hosts:
      - node3
controller_templates_module08:
  - name: Extended services
    organization: Default
    state: present
    inventory: Lab-Inventory
    become_enabled: true
    playbook: extended_services.yml
    project: Additional playbooks
    credential: lab-credentials
  - name: Set motd
    organization: Default
    state: present
    inventory: Lab-Inventory
    become_enabled: true
    playbook: motd_facts.yml
    project: Additional playbooks
    credential: lab-credentials
ENDOFFILE

# Module 09: Workflow
cat > "${CAC_DIR}/configs/module-09/controller_objects.yml" << 'ENDOFFILE'
---
controller_workflows_module09:
  - name: Your first workflow
    description: Create a Workflow from previous Job Templates
    organization: Default
    inventory: Lab-Inventory
    simplified_workflow_nodes:
      - identifier: apache101
        unified_job_template: Install Apache
        success_nodes:
          - extended201
          - motd201
      - identifier: extended201
        unified_job_template: Extended services
      - identifier: motd201
        unified_job_template: Set motd
ENDOFFILE

# Module 10: Survey job template
cat > "${CAC_DIR}/configs/module-10/controller_objects.yml" << 'ENDOFFILE'
---
controller_templates_module10:
  - name: Install Apache with Survey
    organization: Default
    state: present
    inventory: Lab-Inventory
    become_enabled: true
    playbook: apache_template.yml
    project: Apache playbooks
    credential: lab-credentials
    survey_enabled: true
    survey_spec:
      name: Apache Survey
      description: Survey for Apache template deployment
      spec:
        - question_name: "What is your name, fellow student?"
          question_description: "Enter your name or nickname to see it work!"
          variable: student_name
          type: text
          required: false
          default: Skippy
ENDOFFILE

# Staged CaC playbook (main entry point for solve/validation scripts)
cat > "${CAC_DIR}/configure_controller_staged.yml" << 'ENDOFFILE'
---
- name: Configure Automation Controller - Staged Workshop Setup
  hosts: localhost
  connection: local
  gather_facts: false
  vars_files:
    - configs/auth.yml
  vars:
    module: ""
    __module_load_order:
      - module-03
      - module-04
      - module-05
      - module-06
      - module-07
      - module-08
      - module-09
      - module-10
  tasks:
    - name: Validate module parameter
      ansible.builtin.assert:
        that:
          - module | length > 0
          - module == 'all' or module in __module_load_order
        fail_msg: >-
          Please specify a valid module with -e module=<module-name>.
          Valid values: {{ __module_load_order | join(', ') }}, all
      tags: always
    - name: Determine modules to load
      ansible.builtin.set_fact:
        __modules_to_load: >-
          {{
            __module_load_order
            if module == 'all'
            else __module_load_order[:(__module_load_order.index(module) + 1)]
          }}
      tags: always
    - name: Load module configuration variables (cumulative)
      ansible.builtin.include_vars:
        file: "configs/{{ item }}/controller_objects.yml"
      loop: "{{ __modules_to_load }}"
      tags: always
    - name: Merge wildcard-suffixed variables into base names
      ansible.builtin.set_fact:
        "{{ item }}": >-
          {{ query('varnames', '^' ~ item ~ '_') | map('extract', vars) | flatten }}
      loop:
        - controller_inventories
        - controller_hosts
        - controller_groups
        - controller_credentials
        - controller_projects
        - controller_templates
        - controller_workflows
      when: query('varnames', '^' ~ item ~ '_') | length > 0
      tags: always
    - name: Apply credentials
      ansible.builtin.include_role:
        name: infra.aap_configuration.controller_credentials
      when: controller_credentials is defined
      tags: credentials
    - name: Apply projects
      ansible.builtin.include_role:
        name: infra.aap_configuration.controller_projects
      when: controller_projects is defined
      tags: projects
    - name: Apply inventories
      ansible.builtin.include_role:
        name: infra.aap_configuration.controller_inventories
      when: controller_inventories is defined
      tags: inventories
    - name: Apply hosts
      ansible.builtin.include_role:
        name: infra.aap_configuration.controller_hosts
      when: controller_hosts is defined
      tags: hosts
    - name: Apply host groups
      ansible.builtin.include_role:
        name: infra.aap_configuration.controller_host_groups
      when: controller_groups is defined
      tags: host_groups
    - name: Apply job templates
      ansible.builtin.include_role:
        name: infra.aap_configuration.controller_job_templates
      when: controller_templates is defined
      tags: job_templates
    - name: Apply workflow job templates
      ansible.builtin.include_role:
        name: infra.aap_configuration.controller_workflow_job_templates
      when: controller_workflows is defined
      tags: workflow_job_templates
ENDOFFILE

# Credentials-only CaC playbook (for module setup prerequisites)
cat > "${CAC_DIR}/configure_controller_credentials.yml" << 'ENDOFFILE'
---
- name: Configure Automation Controller - Credentials Only
  hosts: localhost
  connection: local
  gather_facts: false
  vars_files:
    - configs/auth.yml
  vars:
    controller_credentials:
      - name: lab-credentials
        credential_type: Machine
        organization: Default
        inputs:
          username: rhel
          password: ansible123!
          ssh_key_data: "{{ lookup('file', '/home/rhel/.ssh/id_rsa') }}"
  tasks:
    - name: Create credentials
      ansible.builtin.include_role:
        name: infra.aap_configuration.controller_credentials
ENDOFFILE

echo "Controller as Code setup complete at ${CAC_DIR}"
