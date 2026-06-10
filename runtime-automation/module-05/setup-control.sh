#!/bin/sh
# Pre-create credentials so they are available for module 05 observation
CAC_DIR="/tmp/controller-as-code"
CAC_VENV="/tmp/cac-venv/bin"

"${CAC_VENV}/ansible-playbook" "${CAC_DIR}/configure_controller_credentials.yml"
