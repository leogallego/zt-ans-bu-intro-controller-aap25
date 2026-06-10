#!/bin/sh
echo "Validating module-03 via Controller as Code" >> /tmp/progress.log

CAC_DIR="/tmp/controller-as-code"
CAC_VENV="/tmp/cac-venv/bin"


# Run CaC in check mode for hosts and groups only
# (inventory check mode falsely reports changed even when inventory exists)
OUTPUT=$("${CAC_VENV}/ansible-playbook" "${CAC_DIR}/configure_controller_staged.yml" -e module=module-03 --check --tags hosts,host_groups 2>&1)
RC=$?

if [ $RC -ne 0 ] || echo "$OUTPUT" | grep -qE "changed=[1-9][0-9]*|failed=[1-9][0-9]*|unreachable=[1-9][0-9]*"; then
  echo "FAIL: Lab-Inventory, hosts (node1, node2), or web group not found."
  echo "Please verify:"
  echo "  - Lab-Inventory exists (case-sensitive)"
  echo "  - node1 and node2 are hosts in Lab-Inventory"
  echo "  - web group exists with node1 and node2"
  echo "Remember names are case-sensitive! Please try again."
  exit 1
fi
