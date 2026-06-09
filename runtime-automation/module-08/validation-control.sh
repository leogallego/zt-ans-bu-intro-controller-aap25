#!/bin/sh
echo "Validating module-08 via Controller as Code" >> /tmp/progress.log

CAC_DIR="/tmp/controller-as-code"
export ANSIBLE_COLLECTIONS_PATH="/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/"


BASE_CMD="ansible-playbook ${CAC_DIR}/configure_controller_staged.yml -e module=module-08 --check"

# Check Extended services and Set motd templates exist
OUTPUT=$(eval "${BASE_CMD} --tags job_templates" 2>&1)
RC=$?
if [ $RC -ne 0 ] || echo "$OUTPUT" | grep -qE "changed=[1-9][0-9]*|failed=[1-9][0-9]*|unreachable=[1-9][0-9]*"; then
  echo "FAIL: Extended services or Set motd template not found or something else is wrong."
  echo "Remember it's case-sensitive! Please try again."
  exit 1
fi

# Check node3 host and database group exist
OUTPUT=$(eval "${BASE_CMD} --tags hosts,host_groups" 2>&1)
RC=$?
if [ $RC -ne 0 ] || echo "$OUTPUT" | grep -qE "changed=[1-9][0-9]*|failed=[1-9][0-9]*|unreachable=[1-9][0-9]*"; then
  echo "FAIL: node3 host not found in Lab-Inventory or database group is missing."
  echo "Please verify:"
  echo "  - node3 is a host in Lab-Inventory"
  echo "  - database group exists with node3"
  exit 1
fi
