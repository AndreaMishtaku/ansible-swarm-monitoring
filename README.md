## Project Overview

This project includes Ansible scripts, Docker Swarm configurations, and various monitoring tools to manage and monitor cloud infrastructure effectively.

## Makefile Usage

The Makefile includes various targets to manage the infrastructure. Below are the details on how to use each target:

- setup-all: Runs the main playbook.
- setup-services-reset: Runs the playbook and starts at the task Install python3-jsondiff.
- setup-services: Runs the playbook and starts at the task Create data directories.
- createfs: Creates the necessary folder structure for Ansible variables and roles.
- createrole <role_name>: Creates a new Ansible role with the specified role name.
- requirements: Installs Ansible collections specified in requirements.yml.
- ping: Pings all hosts in the inventory to test connectivity.

Use

- `vagrant up` to boot the vagrant VMs
- `vagrant destroy -f` to stop them
- `vagrant ssh VCC-control` to access the shell of the VCC control node
  - You will find the playbook inside of the `/vagrant` directory
- `vagrant ssh VCC-target1` to access the shell of the VCC first node
- `vagrant ssh VCC-target2` to access the shell of the VCC second node

## DNS names

Within the scenario machines, `controlnode.vcc.local`, `target1.vcc.local`, and `target2.vcc.local` resolve to the machines IP addresses.

On `target1` and `target2`, `registry.vcc.local` resolves to `127.0.0.1` (the loopback address).

**In order to access the project websites from your own browser you need to add host aliases pointed to one of the nodes ON YOUR HOST**
