# Incus Test Setup

This Terraform configuration creates a reproducible test environment for
protocol testing using Incus containers.

## Prerequisites

1. **Incus**
2. **OpenVSwitch**
3. **Terraform**

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Plan Deployment
```bash
terraform plan
```

### 3. Deploy Infrastructure
```bash
terraform apply
```

### 4. Verify Deployment
```bash
# List containers
incus list

# Check networks
incus network list

# Check profiles
incus profile list

# Test connectivity
incus exec core-router -- ip addr show
```

### 5. Destroy Environment
```bash
terraform destroy
```

## Troubleshooting

### Verify Network Configuration
```bash
incus network show net-ovsbr0
incus profile show prf-router-server
```

### Container Access
```bash
incus exec core-router -- bash
incus shell server
incus exec remote -- ash  # Alpine uses ash shell
```
