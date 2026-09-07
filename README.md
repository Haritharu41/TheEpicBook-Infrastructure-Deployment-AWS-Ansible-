# TheEpicBook — Infrastructure & Deployment (AWS + Ansible)

Infrastructure as Code for provisioning an AWS EC2 host for the **EpicBook** Node.js application, using Terraform for infrastructure and Ansible for configuration/deployment.

## Overview

- **Terraform** (`terraform/aws/`) provisions the AWS infrastructure: a VPC, public subnet, internet gateway, security group, an SSH key pair, and an EC2 instance.
- **Ansible** (`ansible/`) is intended to configure the EC2 instance — installing Node.js, running EpicBook as a systemd service, and fronting it with Nginx as a reverse proxy.



## Repository Structure

```
.
├── terraform/aws/
│   ├── main.tf                              # VPC, subnet, security group, key pair, EC2 instance
│   ├── variable.tf                          # Input variables
│   └── output.tf                            # Outputs (public IP, admin user)
└── ansible/
    ├── inventory.ini                        # Target host(s)
    ├── site.yml                             # Playbook entry point (currently empty)
    ├── group_vars/
    │   └── web.yml                          # Host group variables (currently empty)
    └── roles/
        ├── epicbook/templates/
        │   └── epicbook.service.j2          # systemd unit for the Node app (npm start on :3000)
        └── nginx/templates/
            ├── epicbook.conf.j2             # Nginx reverse-proxy config → 127.0.0.1:3000
            └── epicbook.config.j2           # Alternate Nginx config for serving a static site
```

## Current Status

The Terraform stack is ready to use as-is. The Ansible side has the **templates** for the intended setup but is missing the pieces that actually apply them:

- `ansible/site.yml` — empty. No playbook/plays are defined yet.
- `ansible/group_vars/web.yml` — empty. The templates reference `{{ app_user }}` and `{{ app_dest }}`, which aren't defined anywhere yet.
- `ansible/roles/epicbook/` and `ansible/roles/nginx/` — only contain a `templates/` folder; there are no `tasks/`, `handlers/`, or `defaults/` folders, so nothing currently installs Node.js, deploys the app, or applies these templates.
- Two Nginx templates exist for different purposes: `epicbook.conf.j2` (reverse-proxies to a running Node app on port 3000) and `epicbook.config.j2` (serves a static site directly from `app_dest`). Only one of these should end up being used, depending on how EpicBook is actually run — this hasn't been decided/wired up yet.

In short: today, running `terraform apply` gives you a bare Ubuntu EC2 instance with SSH and HTTP open. There is no working `ansible-playbook` run yet that installs or starts EpicBook.

## Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured (`aws configure`) with credentials that can create VPC/EC2 resources
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 2.9 (for once the playbook is completed)
- SSH key pair at `~/.ssh/id_ed25519` and `~/.ssh/id_ed25519.pub`

## Quick Start

### 1. Provision infrastructure with Terraform

```bash
cd terraform/aws/

terraform init
terraform plan
terraform apply
```

After a successful apply, get the instance's public IP:

```bash
terraform output -raw public_ip
```

### 2. Update the Ansible inventory

Update `ansible/inventory.ini` with the public IP from the Terraform output:

```ini
[web]
<YOUR_PUBLIC_IP>

[web:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### 3. Configure the server (not yet functional)

Once `ansible/site.yml`, `ansible/group_vars/web.yml`, and the `tasks/`/`handlers/` for the `epicbook` and `nginx` roles are filled in, deployment will look like:

```bash
cd ansible/
ansible-playbook -i inventory.ini site.yml
```

At minimum, `group_vars/web.yml` will need to define the variables the existing templates already expect, e.g.:

```yaml
app_user: ubuntu
app_dest: /opt/epicbook
```

## Terraform Variables

| Variable          | Description                              | Default                    |
|--------------------|-------------------------------------------|-----------------------------|
| `aws_region`       | AWS region to deploy into                | `us-east-1`                |
| `project_name`     | Prefix used on all resource names        | `epicbook`                 |
| `ami_id`           | Ubuntu 22.04 LTS AMI ID                  | `ami-0c7217cdde317cfec` (us-east-1) |
| `instance_type`    | EC2 instance type                        | `t3.micro`                 |
| `public_key_path`  | Path to your SSH public key              | `~/.ssh/id_ed25519.pub`    |

Customize by creating a `terraform.tfvars` file, e.g.:

```hcl
aws_region    = "ap-south-1"
instance_type = "t3.small"
```

> Note: if you change `aws_region`, you must also update `ami_id` to a valid Ubuntu 22.04 AMI for that region — the default AMI ID is specific to `us-east-1`.

## Infrastructure Details

### AWS Resources Created

- **VPC**: `10.0.0.0/16`
- **Public Subnet**: `10.0.1.0/24`, with auto-assigned public IPs
- **Internet Gateway** + public route table (`0.0.0.0/0`)
- **Security Group**: allows inbound SSH (22) and HTTP (80) from anywhere, all outbound traffic
- **Key Pair**: created from your local public key
- **EC2 Instance**: Ubuntu 22.04 LTS, `t3.micro` by default

### Intended App Runtime (once Ansible is completed)

- EpicBook runs as a Node.js app (`npm start`) on port `3000`, managed by a systemd service (`epicbook.service.j2`)
- Nginx listens on port 80 and reverse-proxies to `127.0.0.1:3000`, with a separate `/assets` location for static assets

## Cleanup

```bash
cd terraform/aws/
terraform destroy
```

