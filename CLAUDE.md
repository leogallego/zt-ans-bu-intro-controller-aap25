# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

An Instruqt hands-on workshop teaching AAP Automation Controller 2.5 through 10 progressive modules. The `controller-tasks-to-casc` branch replaces the original monolithic shell/playbook approach with **Controller as Code (CaC)** using the `infra.aap_configuration` collection. All Controller object management (inventories, credentials, projects, templates, workflows) is now declarative YAML.

## Lab Content Commands

```bash
# Build the Antora documentation site (outputs to www/)
utilities/lab-build

# Serve locally at http://localhost:8080/index.html
utilities/lab-serve

# Stop the local server
utilities/lab-stop

# Remove generated site
utilities/lab-clean
```

The doc build uses podman with the `antora/antora` image. The server uses `ubi9/httpd-24`.

## Controller as Code Commands

From within `controller-as-code/`:

```bash
# Install required collections
ansible-galaxy collection install -r collections/requirements.yml

# Apply all workshop objects at once (uses dispatch role)
ansible-playbook configure_controller.yml

# Apply up to a specific module (cumulative: includes all prior modules)
ansible-playbook configure_controller_staged.yml -e module=module-06

# Apply all modules
ansible-playbook configure_controller_staged.yml -e module=all

# Validate state without changes
ansible-playbook configure_controller.yml --check

# Apply only specific object types
ansible-playbook configure_controller.yml --tags credentials,projects

# Launch jobs after configuration
ansible-playbook configure_controller_launch.yml --tags launch-apache
ansible-playbook configure_controller_launch.yml --tags launch-workflow

# Execution checks (Apache service verification)
ansible-playbook configure_controller_check.yml --tags check-execution
```

## Architecture

### Three Automation Layers

1. **`setup-automation/`** -- One-time lab provisioning. `main.yml` connects to bastion and dispatches `setup-{host}.sh` scripts. The `setup-control.sh` does infrastructure setup (SSH, ansible-navigator, git) AND writes the entire CaC directory structure to `/tmp/controller-as-code/` on the control node via heredocs.

2. **`runtime-automation/`** -- Per-module lifecycle. `main.yml` dispatches `{setup,solve,validation}-{host}.sh` scripts per module. Only `*-control.sh` scripts interact with Controller; node scripts handle host-level setup.

3. **`controller-as-code/`** -- Standalone CaC reference (same content as what `setup-control.sh` writes to `/tmp/`). Four playbooks with distinct responsibilities:
   - `configure_controller.yml` -- full apply via `dispatch` role (all objects inline)
   - `configure_controller_staged.yml` -- per-module apply (cumulative loading)
   - `configure_controller_check.yml` -- validation with execution checks
   - `configure_controller_launch.yml` -- job/workflow launches (non-idempotent, separated intentionally)

### CaC Variable Pattern

Config files use **wildcard-suffixed variables** (`controller_hosts_module03`, `controller_hosts_module08`) that get merged into base names (`controller_hosts`) via `query('varnames')`. This allows cumulative module loading without overwrites.

Each module's objects live in `configs/module-XX/controller_objects.yml`. The staged playbook loads modules 03 through the target module in order -- running `-e module=module-09` loads everything from 03 to 09 because later modules depend on earlier objects.

### Runtime Script Patterns

**Solve scripts**: Run `configure_controller_staged.yml -e module=module-XX` to create all objects up to that module.

**Validation scripts**: Run the same staged playbook with `--check` and optional `--tags`, then parse PLAY RECAP for `changed=[1-9]|failed=[1-9]|unreachable=[1-9]`. Each module has specific user-facing error messages.

**Setup scripts** (modules 04, 05): Pre-create credentials via `configure_controller_credentials.yml` so they exist before the student reaches the module.

### Dual Maintenance Requirement

The CaC content exists in **two places that must stay in sync**:
- `controller-as-code/configs/` -- standalone reference files (source of truth)
- `setup-automation/setup-control.sh` -- heredoc copies deployed to `/tmp/controller-as-code/` at runtime

When modifying Controller objects, update both locations.

## Workshop Module Progression

Modules 01-02 are informational (no Controller objects). Modules 03-10 each add objects that build on previous modules:

- **03**: Lab-Inventory, hosts (node1, node2), group (web)
- **04**: Project (Apache playbooks, git)
- **05**: Credential (lab-credentials, Machine type)
- **06**: Job Template (Install Apache)
- **07**: Project (Additional playbooks, git)
- **08**: Host (node3), group (database), Job Templates (Extended services, Set motd)
- **09**: Workflow (apache101 -> extended201 + motd201)
- **10**: Job Template with Survey (student_name variable)

## Key Collections

- `infra.aap_configuration` -- CaC roles for all Controller objects
- `ansible.controller` -- Controller API modules (used in launch/check playbooks)
- `ansible.platform` -- AAP platform modules

## Content Authoring

Lab content is AsciiDoc under `content/modules/ROOT/pages/module-XX.adoc`, built with Antora. Site config is in `site.yml`, component descriptor in `content/antora.yml`. The `ui-config.yml` and images under `content/modules/ROOT/assets/images/` support the UI.

## Platform Config

Lab infrastructure is defined in `config/`:
- `instances.yaml` -- VMs (control with AAP 2.5, node1-3 as RHEL 9.5) and containers (Gitea)
- `networks.yaml` -- Network topology
- `firewall.yaml` -- Firewall rules

The control VM uses the `base-zero-aap-2.5-container-ce` image with 16G RAM / 4 cores.
