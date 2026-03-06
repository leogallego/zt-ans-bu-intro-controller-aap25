#!/bin/sh
echo "Validating module-06 via Controller as Code" >> /tmp/progress.log

CAC_DIR="/tmp/controller-as-code"
export ANSIBLE_COLLECTIONS_PATH="/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/"
export ANSIBLE_STDOUT_CALLBACK="community.general.yaml"

# Run CaC in check mode for job templates only
OUTPUT=$(ansible-playbook "${CAC_DIR}/configure_controller_staged.yml" -e module=module-06 --check --tags job_templates 2>&1)
RC=$?

if [ $RC -ne 0 ] || echo "$OUTPUT" | grep -qE "changed=[1-9]|failed=[1-9]|unreachable=[1-9]"; then
  echo "FAIL: Install Apache job template not found or something else is wrong."
  echo "Remember it's case-sensitive! Please try again."
  exit 1
fi
