# CAC-CONTROLLER-101: Controller as Code Evaluation & Implementation

## Overview

This document captures the evaluation of the "Introduction to Ansible Automation Controller 2.5" hands-on workshop and the alternative implementation using the `infra.aap_configuration` collection (Controller as Code approach).

**Collection**: [infra.aap_configuration](https://github.com/redhat-cop/infra.aap_configuration)
**Workshop**: zt-ans-bu-intro-controller-aap25

---

## Workshop Structure (Original)

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
- Credential: lab-credentials (Machine type with SSH key)
- Demo Inventory (for reference)
- Demo Project (for reference)

---

## Problems with the Current Approach

### 1. Shell Script Anti-Pattern
`setup-automation/setup-control.sh` (857 lines) embeds an entire Ansible playbook as a heredoc inside a bash script, mixing infrastructure setup (SSH keys, packages, network) with Controller configuration.

### 2. Hardcoded Credentials (30+ repetitions)
Every single task repeats all four connection parameters:
```yaml
controller_host: "https://localhost"
controller_username: admin
controller_password: ansible123!
validate_certs: false
```

### 3. No Data/Logic Separation
Controller objects (inventories, projects, templates) are defined inline in tasks rather than as declarative variables.

### 4. No Use of infra.aap_configuration
Uses raw `ansible.controller` modules directly instead of the standardized CaC dispatch role.

### 5. Tag Explosion
Complex tag combinations (`solve-inventory-all`, `solve-workflow`, `solve-all`, `check-all`, etc.) instead of clean module-based selection.

### 6. Duplicated Check Tasks
Every create task is duplicated as a check task (~400 lines of checks mirror ~400 lines of creates).

---

## CaC Alternative Implementation

### Directory Structure

```
controller-as-code/
├── ansible.cfg
├── collections/
│   └── requirements.yml              # Collection dependencies
├── configs/
│   ├── auth.yml                       # AAP connection (vault-encrypt in prod)
│   ├── module-03/controller_objects.yml  # Inventory, hosts, groups
│   ├── module-04/controller_objects.yml  # Apache playbooks project
│   ├── module-05/controller_objects.yml  # lab-credentials
│   ├── module-06/controller_objects.yml  # Install Apache JT
│   ├── module-07/controller_objects.yml  # Additional playbooks project
│   ├── module-08/controller_objects.yml  # node3, database group, 2 more JTs
│   ├── module-09/controller_objects.yml  # Workflow template
│   └── module-10/controller_objects.yml  # Survey JT
├── configure_controller.yml           # Full apply (replaces solve-all)
├── configure_controller_staged.yml    # Per-module apply (replaces solve-* tags)
├── configure_controller_check.yml     # Validation (replaces check-* tags)
└── configure_controller_launch.yml    # Job launches (separated from config)
```

### Key Design Decisions

1. **Wildcard variable merging** (`dispatch_include_wildcard_vars: true`): Variables like `controller_hosts_module03` and `controller_hosts_module08` are automatically merged into `controller_hosts` by the dispatch role. This allows per-module files without overwrite conflicts.

2. **Cumulative module loading**: Running `-e module=module-09` loads modules 03 through 09, because the workflow depends on all prior objects existing.

3. **Separated launch playbook**: Job launches (`job_launch`, `workflow_launch`) are in a separate playbook because they are not idempotent. The CaC config playbooks are fully idempotent.

4. **Dependency ordering handled by dispatch**: The `dispatch` role automatically applies objects in the correct order (credentials -> projects -> templates -> workflows) regardless of the order in variable files.

### Usage

```bash
# Install the collection
ansible-galaxy collection install -r collections/requirements.yml

# Apply ALL workshop objects at once (replaces solve-all)
ansible-playbook configure_controller.yml

# Apply up to module 06 only (cumulative: includes 03, 04, 05, 06)
ansible-playbook configure_controller_staged.yml -e module=module-06

# Apply all modules
ansible-playbook configure_controller_staged.yml -e module=all

# Validate everything matches desired state (replaces check-all)
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

| Metric | Original setup-control.sh | CaC Alternative |
|--------|---------------------------|-----------------|
| Total lines of AAP config | ~857 (shell + embedded playbook) | ~150 (across all YAML files) |
| Times credentials appear | 30+ | 1 |
| Number of explicit tasks | ~45 (create + check duplicated) | 0 (dispatch handles it) |
| Playbooks | 1 monolithic heredoc in shell | 4 focused playbooks |
| Check mode support | Manual duplication of every task | Built-in via --check flag |
| Dependency ordering | Manual task ordering | Automatic via dispatch |

---

## Workshop Objects - Complete Variable Reference

### Inventory (Module 03)
```yaml
controller_inventories:
  - name: Lab-Inventory
    organization: Default
```

### Hosts (Modules 03, 08)
```yaml
controller_hosts:
  - name: node1
    inventory: Lab-Inventory
  - name: node2
    inventory: Lab-Inventory
  - name: node3
    inventory: Lab-Inventory
```

### Groups (Modules 03, 08)
```yaml
controller_groups:
  - name: web
    inventory: Lab-Inventory
    hosts: [node1, node2]
  - name: database
    inventory: Lab-Inventory
    hosts: [node3]
```

### Credentials (Module 05)
```yaml
controller_credentials:
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
controller_projects:
  - name: Apache playbooks
    organization: Default
    scm_type: git
    scm_url: https://github.com/ansible-tmm/instruqt-wyfp.git
    wait: true
  - name: Additional playbooks
    organization: Default
    scm_type: git
    scm_url: https://github.com/ansible-tmm/instruqt-wyfp-additional.git
    wait: true
```

### Job Templates (Modules 06, 08, 10)
```yaml
controller_templates:
  - name: Install Apache
    organization: Default
    inventory: Lab-Inventory
    become_enabled: true
    playbook: apache.yml
    project: Apache playbooks
    credential: lab-credentials
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
controller_workflows:
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
