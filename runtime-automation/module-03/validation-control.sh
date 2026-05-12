#!/bin/sh
echo "Validated module called module-02" >> /tmp/progress.log
# set -e
# INVENTORY="Lab-Inventory"
# HOSTS=(node1 node2)
# GROUP="web"
# #Ansible settings
# export ANSIBLE_STDOUT_CALLBACK="community.general.yaml"
# ## Check all
# CMDALL="ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags check-inventory-all"
# ## Check $INVENTORY exists.
# CMDINV="ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags check-inventory"
# if ! eval "$CMDINV"; then
#   echo "FAIL: ${INVENTORY} inventory not found. Remember it's case-sensitive! Please try again."
#   exit 1
# fi
# ## Check hosts are in $INVENTORY
# CMDHOSTS="ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags check-inv-hosts"
# for host in "${HOSTS[@]}"; do
#   if ! eval "$CMDHOSTS"; then
#     echo "FAIL: node1 or node2 are missing from ${INVENTORY} or there is a duplicate host in another inventory. If so, please remove the duplicate ${host} host and check again. Remember it's case-sensitive!"
#     exit 1
#   fi
# done
# ## Check $GROUP is in $INVENTORY
# CMDGROUP="ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags check-inv-group"
# if ! eval "$CMDGROUP"; then
#     echo "FAIL: ${GROUP} group is missing, node1 and node2 are not in the group, or there is a duplicate ${GROUP} group in another inventory. If so, please remove the duplicate ${GROUP} group and check again. Remember it's case-sensitive!"
#     echo "Remember it's case-sensitive! Please try again."
#     exit 1
# fi
