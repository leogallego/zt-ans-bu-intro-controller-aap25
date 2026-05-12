#!/bin/sh
echo "Validated module called module-02" >> /tmp/progress.log
# set -e
# INVENTORY="Lab-Inventory"
# PROJECT="Apache playbooks"
# PROJECT2="Additional playbooks"
# TEMPLATE="Install Apache"
# TEMPLATE2="Set motd"
# TEMPLATE3="Extended services"
# WORKFLOW="Your first workflow"
# HOSTS=(node1 node2)
# GROUP="web"
# #Ansible settings
# export ANSIBLE_STDOUT_CALLBACK="yaml"
# ## Run --tags check-project2
# CMD="ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags check-project2"
# # Check $PROJECT2 exists.
# if ! eval "$CMD"; then
#   echo "FAIL: ${PROJECT2} project not found or something else is wrong. Remember it's case-sensitive! Please try again."
#   exit 1
# fi
