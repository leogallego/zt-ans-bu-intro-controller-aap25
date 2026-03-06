# CAC-CONTROLLER-101: Controller as Code Evaluation & Implementation

## Overview

This document captures the evaluation of the "Introduction to Ansible Automation Controller 2.5" hands-on workshop and the full migration to the `infra.aap_configuration` collection (Controller as Code approach).

**Collection**: [infra.aap_configuration](https://github.com/redhat-cop/infra.aap_configuration)
**Workshop**: zt-ans-bu-intro-controller-aap25
**Branch**: `controller-tasks-to-casc`
**Status**: Full migration complete — solve, validation, and setup scripts all use CaC

---

## Workshop Structure

The workshop consists of 10 modules that progressively teach AAP Controller concepts:

| Module | Topic | Controller Objects Created |
|--------|-------|---------------------------|
| 01 | Welcome / AAP Overview | None (informational) |
| 02 | Controller UI Exploration | None (exploration of Demo objects) |
| 03 | Creating an Inventory | Lab-Inventory, hosts (node1, node2), group (web) |
| 04 | Creating Your First Project | Project: Apache playbooks (git: ansible-tmm/instruqt-wyfp) |
| 05 | Understanding Credentials | Credential: lab-credentials (Machine type, SSH key) |
| 06 | Creating a Job Template | JT: Install Apache |
| 07 | Creating a Second Project | Project: Additional playbooks (git: ansible-tmm/instruqt-wyfp-additional) |
| 08 | Creating Multiple Job Templates | Host: node3, group: database, JTs: Extended services, Set motd |
| 09 | Creating a Workflow | Workflow: Your first workflow (3 nodes: apache101 -> extended201 + motd201) |
| 10 | Job Template with Survey | JT: Install Apache with Survey (student_name variable) |

### Pre-configured Objects (Not User-Created)
- Credential: lab-credentials (Machine type with SSH key) — created by setup scripts via CaC
- Demo Inventory (for reference)
- Demo Project (for reference)

---

## Migration Summary

### What Was Replaced

The original workshop used a monolithic approach:
- `setup-automation/setup-control.sh` (857 lines) embedded an entire Ansible playbook (`/tmp/setup.yml`) as a heredoc, mixing infrastructure setup with Controller configuration
- Credentials were hardcoded 30+ times across ~45 tasks
- Every create task was duplicated as a check task (~400 lines of checks)
- Complex tag combinations (`solve-inventory-all`, `solve-workflow`, `solve-all`, `check-all`) drove solve/validation scripts
- No data/logic separation — Controller objects defined inline in tasks

### What Replaced It

All Controller configuration now uses `infra.aap_configuration` with declarative YAML variables:

| Component | Before | After |
|-----------|--------|-------|
| **setup-control.sh** | 857 lines (infra + 710-line heredoc) | ~340 lines (infra + CaC directory creation) |
| **solve scripts** (8 files) | `ansible-playbook --tags solve-*` against monolith | `ansible-playbook configure_controller_staged.yml -e module=module-XX` |
| **validation scripts** (6 files) | `ansible-playbook --tags check-*` against monolith | PLAY RECAP parsing with `--check` on CaC playbook |
| **setup scripts** (modules 04, 05) | `ansible-playbook --tags solve-credentials` | `ansible-playbook configure_controller_credentials.yml` |
| **Net line change** | — | **-555 lines** (356 added, 911 removed) |

---

## Architecture After Migration

### Runtime Flow

```
Workshop Platform (Instruqt)
  │
  ├── setup-automation/main.yml
  │     └── setup-control.sh
  │           ├── Infrastructure setup (SSH, packages, ansible-navigator)
  │           ├── ansible-galaxy collection install infra.aap_configuration
  │           └── Creates /tmp/controller-as-code/ directory with:
  │                 ├── configs/auth.yml
  │                 ├── configs/module-{03..10}/controller_objects.yml
  │                 ├── configure_controller_staged.yml
  │                 └── configure_controller_credentials.yml
  │
  └── runtime-automation/main.yml (dispatches per-module scripts)
        ├── setup-control.sh    → Runs ansible-navigator images (or credentials for mod 04/05)
        ├── solve-control.sh    → ansible-playbook configure_controller_staged.yml -e module=module-XX
        └── validation-control.sh → Same playbook with --check, parse PLAY RECAP
```

### CaC Directory on Control Node (`/tmp/controller-as-code/`)

```
/tmp/controller-as-code/
├── configs/
│   ├── auth.yml                          # AAP connection (aap_hostname, aap_username, etc.)
│   ├── module-03/controller_objects.yml  # Inventory, hosts, groups
│   ├── module-04/controller_objects.yml  # Apache playbooks project
│   ├── module-05/controller_objects.yml  # lab-credentials
│   ├── module-06/controller_objects.yml  # Install Apache JT
│   ├── module-07/controller_objects.yml  # Additional playbooks project
│   ├── module-08/controller_objects.yml  # node3, database group, 2 more JTs
│   ├── module-09/controller_objects.yml  # Workflow template
│   └── module-10/controller_objects.yml  # Survey JT
├── configure_controller_staged.yml       # Main CaC playbook (cumulative module loading)
└── configure_controller_credentials.yml  # Credentials-only playbook (for module setup)
```

### Standalone CaC Reference (`controller-as-code/` in repo root)

```
controller-as-code/
├── ansible.cfg
├── collections/
│   └── requirements.yml
├── configs/
│   ├── auth.yml
│   └── module-{03..10}/controller_objects.yml
├── configure_controller.yml              # Full apply (all objects inline)
├── configure_controller_staged.yml       # Per-module apply (cumulative)
├── configure_controller_check.yml        # Validation with execution checks
├── configure_controller_launch.yml       # Job/workflow launches
└── CAC-CONTROLLER-101.md                 # This file
```

---

## Key Design Decisions

### 1. Wildcard Variable Merging

Variables use suffixed names (`controller_hosts_module03`, `controller_hosts_module08`) so the dispatch role's `dispatch_include_wildcard_vars: true` automatically merges them into `controller_hosts`. This allows per-module config files to be loaded cumulatively without overwriting each other.

### 2. Cumulative Module Loading

Running `-e module=module-09` loads modules 03 through 09, because the workflow depends on all prior objects existing. The `__module_load_order` list defines the sequence.

### 3. Separated Concerns

- **Configuration** (idempotent, safe to re-run): `configure_controller_staged.yml`
- **Credential pre-creation** (for setup scripts): `configure_controller_credentials.yml`
- **Job launches** (not idempotent): `configure_controller_launch.yml`
- **Validation** (check mode): Same staged playbook with `--check` flag

### 4. Dependency Ordering via Dispatch

The `infra.aap_configuration.dispatch` role automatically applies objects in the correct order (credentials -> projects -> inventories -> hosts -> groups -> templates -> workflows) regardless of the order in variable files.

### 5. Validation Strategy

Validation scripts run the CaC staged playbook with `--check` and parse the PLAY RECAP output:
- `changed=0` → all objects exist and match desired state (PASS)
- `changed=[1-9]` or `failed=[1-9]` → objects missing or misconfigured (FAIL)

Each validation script preserves user-friendly error messages explaining what the student should have created.

---

## Script Reference

### Solve Scripts (all follow same pattern)

```bash
#!/bin/sh
CAC_DIR="/tmp/controller-as-code"
export ANSIBLE_COLLECTIONS_PATH="/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/"

ansible-playbook "${CAC_DIR}/configure_controller_staged.yml" -e module=module-XX
```

### Validation Scripts (all follow same pattern)

```bash
#!/bin/sh
CAC_DIR="/tmp/controller-as-code"
export ANSIBLE_COLLECTIONS_PATH="..."

OUTPUT=$(ansible-playbook "${CAC_DIR}/configure_controller_staged.yml" \
  -e module=module-XX --check [--tags <object_type>] 2>&1)
RC=$?

if [ $RC -ne 0 ] || echo "$OUTPUT" | grep -qE "changed=[1-9]|failed=[1-9]|unreachable=[1-9]"; then
  echo "FAIL: <specific error message for the module>"
  exit 1
fi
```

### Validation Tags Per Module

| Module | `--tags` Used | What Is Checked |
|--------|---------------|-----------------|
| 03 | (none — checks all) | Lab-Inventory, node1, node2, web group |
| 04 | `projects` | Apache playbooks project |
| 06 | `job_templates` | Install Apache JT |
| 07 | `projects` | Additional playbooks project |
| 08 | `job_templates` then `hosts,host_groups` | Extended services, Set motd, node3, database group |
| 09 | `workflow_job_templates` | Your first workflow |
| 05, 10 | (no validation) | Stubs — credentials are pre-loaded, survey has no check |

### Setup Scripts (modules 04, 05)

Pre-create credentials before the student reaches the module:

```bash
#!/bin/sh
CAC_DIR="/tmp/controller-as-code"
export ANSIBLE_COLLECTIONS_PATH="..."

ansible-playbook "${CAC_DIR}/configure_controller_credentials.yml"
```

---

## Standalone CaC Usage

The `controller-as-code/` directory in the repo root provides standalone playbooks for use outside the Instruqt workshop platform:

```bash
# Install the collection
ansible-galaxy collection install -r collections/requirements.yml

# Apply ALL workshop objects at once
ansible-playbook configure_controller.yml

# Apply up to module 06 only (cumulative: includes 03, 04, 05, 06)
ansible-playbook configure_controller_staged.yml -e module=module-06

# Apply all modules
ansible-playbook configure_controller_staged.yml -e module=all

# Validate everything matches desired state
ansible-playbook configure_controller.yml --check

# Apply only specific object types with tags
ansible-playbook configure_controller.yml --tags credentials,projects

# Launch job templates after configuration
ansible-playbook configure_controller_launch.yml --tags launch-apache

# Launch workflow
ansible-playbook configure_controller_launch.yml --tags launch-workflow

# Run execution checks (Apache service verification)
ansible-playbook configure_controller_check.yml --tags check-execution
```

---

## infra.aap_configuration Collection Reference

### Variable Naming Conventions

- **`aap_*`** -- Shared/cross-service objects: `aap_organizations`, `aap_teams`, `aap_user_accounts`
- **`controller_*`** -- Controller-specific: `controller_projects`, `controller_credentials`, `controller_templates`, `controller_inventories`, `controller_workflows`
- **`hub_*`** -- Hub-specific: `hub_namespaces`, `hub_ee_registries`
- **`gateway_*`** -- Gateway-specific: `gateway_authenticators`, `gateway_settings`
- **`eda_*`** -- EDA-specific: `eda_projects`, `eda_credentials`

### Authentication Variables
- `aap_hostname` -- AAP URL (required)
- `aap_username` / `aap_password` -- basic auth
- `aap_token` -- OAuth token (preferred in production)
- `aap_validate_certs` -- SSL verification (default: true)

### Controller Roles (Dispatch Execution Order)

| Role | Variable | Tag |
|------|----------|-----|
| `controller_settings` | `controller_settings` | `settings` |
| `controller_credential_types` | `controller_credential_types` | `credential_types` |
| `controller_credentials` | `controller_credentials` | `credentials` |
| `controller_execution_environments` | `controller_execution_environments` | `execution_environments` |
| `controller_projects` | `controller_projects` | `projects` |
| `controller_inventories` | `controller_inventories` | `inventories` |
| `controller_inventory_sources` | `controller_inventory_sources` | `inventory_sources` |
| `controller_hosts` | `controller_hosts` | `hosts` |
| `controller_host_groups` | `controller_groups` | `host_groups` |
| `controller_job_templates` | `controller_templates` | `job_templates` |
| `controller_workflow_job_templates` | `controller_workflows` | `workflow_job_templates` |
| `controller_schedules` | `controller_schedules` | `schedules` |
| `controller_roles` | `controller_roles` | `roles` |
| `controller_job_launch` | `controller_launch_jobs` | `job_launch` |
| `controller_workflow_launch` | `controller_workflow_launch_jobs` | `workflow_launch` |

Each role is **skipped** if its corresponding variable is not defined.

### Key Features

- **Wildcard variable merging**: Set `dispatch_include_wildcard_vars: true` and variables like `controller_projects_dev` + `controller_projects_prod` are auto-merged into `controller_projects`.
- **Error collection**: Set `aap_configuration_collect_logs: true` to continue through errors and collect them in `aap_configuration_role_errors`.
- **Role exclusion**: Use `aap_configuration_dispatcher_exclude_roles` to skip specific roles.
- **Idempotent by design**: All roles are idempotent; running twice produces no changes.
- **Tag-based selective execution**: Every role has tags for `--tags credentials,projects` usage.

---

## Complexity Reduction Summary

| Metric | Original (pre-migration) | CaC (post-migration) |
|--------|--------------------------|----------------------|
| Total lines of AAP config | ~857 (shell + embedded playbook) | ~200 (CaC heredocs in setup script) |
| Times credentials appear | 30+ | 1 (in configs/auth.yml) |
| Number of explicit tasks | ~45 (create + check duplicated) | 0 (dispatch handles it) |
| Solve script complexity | Tag-based, 3+ ansible-playbook calls per module | 1 command per module |
| Validation script complexity | 4 separate check commands (module 03) | 1 command with PLAY RECAP parsing |
| /tmp/setup.yml references | 16 across all scripts | 0 |
| Net line change | — | **-555 lines** |

---

## Workshop Objects - Complete Variable Reference

### Inventory (Module 03)
```yaml
controller_inventories_module03:
  - name: Lab-Inventory
    organization: Default
```

### Hosts (Modules 03, 08)
```yaml
controller_hosts_module03:
  - name: node1
    inventory: Lab-Inventory
  - name: node2
    inventory: Lab-Inventory

controller_hosts_module08:
  - name: node3
    inventory: Lab-Inventory
```

### Groups (Modules 03, 08)
```yaml
controller_groups_module03:
  - name: web
    inventory: Lab-Inventory
    hosts: [node1, node2]

controller_groups_module08:
  - name: database
    inventory: Lab-Inventory
    hosts: [node3]
```

### Credentials (Module 05)
```yaml
controller_credentials_module05:
  - name: lab-credentials
    credential_type: Machine
    organization: Default
    inputs:
      username: rhel
      password: ansible123!
      ssh_key_data: "{{ lookup('file', '/home/rhel/.ssh/id_rsa') }}"
```

### Projects (Modules 04, 07)
```yaml
controller_projects_module04:
  - name: Apache playbooks
    organization: Default
    scm_type: git
    scm_url: https://github.com/ansible-tmm/instruqt-wyfp.git
    wait: true

controller_projects_module07:
  - name: Additional playbooks
    organization: Default
    scm_type: git
    scm_url: https://github.com/ansible-tmm/instruqt-wyfp-additional.git
    wait: true
```

### Job Templates (Modules 06, 08, 10)
```yaml
controller_templates_module06:
  - name: Install Apache
    organization: Default
    inventory: Lab-Inventory
    become_enabled: true
    playbook: apache.yml
    project: Apache playbooks
    credential: lab-credentials

controller_templates_module08:
  - name: Extended services
    organization: Default
    inventory: Lab-Inventory
    become_enabled: true
    playbook: extended_services.yml
    project: Additional playbooks
    credential: lab-credentials
  - name: Set motd
    organization: Default
    inventory: Lab-Inventory
    become_enabled: true
    playbook: motd_facts.yml
    project: Additional playbooks
    credential: lab-credentials

controller_templates_module10:
  - name: Install Apache with Survey
    organization: Default
    inventory: Lab-Inventory
    become_enabled: true
    playbook: apache_template.yml
    project: Apache playbooks
    credential: lab-credentials
    survey_enabled: true
    survey_spec:
      name: Apache Survey
      spec:
        - question_name: "What is your name, fellow student?"
          variable: student_name
          type: text
          required: false
          default: Skippy
```

### Workflow (Module 09)
```yaml
controller_workflows_module09:
  - name: Your first workflow
    description: Create a Workflow from previous Job Templates
    organization: Default
    inventory: Lab-Inventory
    simplified_workflow_nodes:
      - identifier: apache101
        unified_job_template: Install Apache
        success_nodes: [extended201, motd201]
      - identifier: extended201
        unified_job_template: Extended services
      - identifier: motd201
        unified_job_template: Set motd
```
