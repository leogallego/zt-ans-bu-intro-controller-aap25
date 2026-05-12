#!/bin/sh
echo "Validated module called module-02" >> /tmp/progress.log
# set -e
# INVENTORY="lab-inventory"
# PROJECT="Apache playbooks"
# PROJECT2="Additional playbooks"
# TEMPLATE_APACHE="Install Apache"
# TEMPLATE_MOTD="Set motd"
# TEMPLATE_EXT="Extended services"
# WORKFLOW="Your first workflow"
# HOSTS=(node1 node2)
# GROUP="web"
# #Ansible settings
# export ANSIBLE_STDOUT_CALLBACK="yaml"
# ## Run --tags check-project 
# #CMD="su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --mode stdout'"
# CMD1="ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags check-job_template2"
# CMD2="ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags check-node3"
# CMD3="ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags check-database"
# CMD4="ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags check-job_template3"
# # Check $TEMPLATE_EXT exists.
# if ! eval "$CMD1"; then
#   echo "FAIL: ${TEMPLATE_EXT} template not found or something else is wrong. Remember it's case-sensitive! Please try again."
#   exit 1
# fi
# # Check node3 exists.
# if ! eval "$CMD2"; then
#   echo "FAIL: node3 host not found in Lab-Inventory or something is missing. Please try again."
#   exit 1
# fi
# # Check database group exists.
# if ! eval "$CMD3"; then
#   echo "FAIL: [database] group not found or node3 is missing from the group. Please try again."
#   exit 1
# fi
# # Check $TEMPLATE_MOTD exists.
# if ! eval "$CMD4"; then
#   echo "FAIL: ${TEMPLATE_MOTD} template not found or something is missing. Please try again."
#   exit 1
# fi
