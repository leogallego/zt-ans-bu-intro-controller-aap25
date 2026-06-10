#!/bin/sh
echo "Solving module-10 via Controller as Code" >> /tmp/progress.log

CAC_DIR="/tmp/controller-as-code"
export ANSIBLE_COLLECTIONS_PATH="/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/"

ansible-playbook "${CAC_DIR}/configure_controller_staged.yml" -e module=module-10
