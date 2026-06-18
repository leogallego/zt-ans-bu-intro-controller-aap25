#!/bin/sh
echo "Validating module-06 via Controller as Code" >> /tmp/progress.log

CAC_DIR="/tmp/controller-as-code"
CAC_VENV="/tmp/cac-venv/bin"


# Run CaC in check mode for job templates only
OUTPUT=$("${CAC_VENV}/ansible-playbook" "${CAC_DIR}/configure_controller_staged.yml" -e module=module-06 --check --tags job_templates 2>&1)
RC=$?

if [ $RC -ne 0 ] || echo "$OUTPUT" | grep -qE "changed=[1-9][0-9]*|failed=[1-9][0-9]*|unreachable=[1-9][0-9]*"; then
  echo "FAIL: Install Apache job template not found or something else is wrong."
  echo "Remember it's case-sensitive! Please try again."
  exit 1
fi
