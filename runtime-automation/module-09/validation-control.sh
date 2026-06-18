#!/bin/sh
echo "Validating module-09 via Controller module" >> /tmp/progress.log

CAC_DIR="/tmp/controller-as-code"
CAC_VENV="/tmp/cac-venv/bin"

# Use state=exists instead of CaC --check
# (CaC --check always reports changed for workflow node relationships)
OUTPUT=$("${CAC_VENV}/ansible-playbook" "${CAC_DIR}/configure_controller_validate_workflow.yml" 2>&1)
RC=$?

if [ $RC -ne 0 ] || echo "$OUTPUT" | grep -qE "failed=[1-9][0-9]*|unreachable=[1-9][0-9]*"; then
  echo "FAIL: Your first workflow template not found or something else is wrong."
  echo "Remember it's case-sensitive! Please try again."
  exit 1
fi
