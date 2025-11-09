# Pkl Infrastructure Configuration

This repository contains a **complete infrastructure-as-code setup** using Pkl that regenerates all your configuration files from a single source of truth.

## What This Solves

- ✅ **No more escape sequence hell** - Pkl handles all escaping automatically
- ✅ **Type-safe configurations** - Catch errors before deployment
- ✅ **Single source of truth** - All configs generated from one place
- ✅ **Fresh OS rebuilds** - Regenerate everything in seconds
- ✅ **Credential management** - Centralized, secure, gitignored secrets

## Quick Start

### 1. Install Pkl

```bash
# Download Pkl (Linux)
curl -L -o /tmp/pkl https://github.com/apple/pkl/releases/download/0.30.0/pkl-linux-amd64
chmod +x /tmp/pkl
sudo mv /tmp/pkl /usr/local/bin/pkl

# Verify installation
pkl --version
```

**Alternative installations:**
- macOS: `brew install pkl`
- Other platforms: https://pkl-lang.org/main/current/pkl-cli/index.html#installation

### 2. Configure Your Secrets

```bash
# Copy the template
cp pkl-config/secrets.pkl.template pkl-config/secrets.pkl

# Edit with your actual credentials
nano pkl-config/secrets.pkl
```

**Fill in:**
- AWS credentials (access key, secret key, region, snapshot role ARN)
- MCP server credentials (Mantis crystals key, mobile bridge token)
- Kubernetes credentials (cluster endpoint, API token, namespace)
- GitHub credentials (PAT, username)

### 3. Generate All Configurations

```bash
# Run the build script
./rebuild-configs.sh
```

This generates:
- **Claude Desktop MCP config** → `~/.config/claude_desktop_config.json`
- **AWS credentials** → `~/.aws/credentials`
- **AWS config** → `~/.aws/config`
- **Environment file** → `generated-configs/.env`
- **Kubernetes manifests** → `generated-configs/k8s-*.yaml`

### 4. Apply Configurations

```bash
# Source environment variables
source generated-configs/.env

# Apply Kubernetes manifests (if using K8s)
kubectl apply -f generated-configs/k8s-namespace.yaml
kubectl apply -f generated-configs/k8s-agents.yaml
kubectl apply -f generated-configs/k8s-service.yaml

# Restart Claude Desktop to load MCP servers
# (macOS: Cmd+Q and reopen, Linux: kill claude-desktop process)
```

## Architecture

```
pkl-config/
├── secrets.pkl.template     # Template for credentials (commit this)
├── secrets.pkl              # Your actual secrets (NEVER commit this)
├── infrastructure.pkl       # Main orchestration module
├── mcp-servers.pkl          # MCP server configurations
├── aws-config.pkl           # AWS credentials & config generator
└── kubernetes.pkl           # K8s manifest generator

rebuild-configs.sh           # Build script to regenerate everything

generated-configs/           # Output directory (gitignored)
├── claude_desktop_config.json
├── aws_credentials
├── aws_config
├── .env
├── k8s-namespace.yaml
├── k8s-agents.yaml
└── k8s-service.yaml
```

## Configuration Modules

### 1. MCP Servers (`mcp-servers.pkl`)

Generates `claude_desktop_config.json` with MCP server registrations:

- **mantis-mcp-server** - Defensive security operations with Crystals key
- **claude-code-bridge** - Local filesystem bridge for Claude Code
- **mobile-bridge** - iOS/Android device integration
- **aws-snapshot-manager** - EBS snapshot operations
- **filesystem** - Extended file operations via MCP
- **git** - Git operations via MCP

### 2. AWS Configuration (`aws-config.pkl`)

Generates:
- `~/.aws/credentials` - Access keys and role configurations
- `~/.aws/config` - Region settings and profile configurations

Includes:
- Default profile with access keys
- Snapshot role profile for EBS operations

### 3. Kubernetes (`kubernetes.pkl`)

Generates K8s manifests for AutoSecure Platform:
- Namespace configuration
- Agent deployments (agent-1, agent-2, agent-3)
- LoadBalancer service for agent access

Each agent deployment includes:
- AWS credentials as environment variables
- Resource limits (CPU/memory)
- Health probes and scaling configuration

### 4. Environment Variables (`infrastructure.pkl`)

Generates `.env` file with:
- AWS environment variables
- MCP server paths and tokens
- Kubernetes configuration
- GitHub credentials

## Customization

### Adding a New MCP Server

Edit `pkl-config/mcp-servers.pkl`:

```pkl
["my-new-server"] = new {
  command = "/path/to/server"
  args = new Listing {
    "--flag"
    "value"
  }
  env = new {
    MY_VAR = "value"
  }
}
```

Run `./rebuild-configs.sh` to regenerate.

### Modifying Kubernetes Agents

Edit `pkl-config/kubernetes.pkl`:

```pkl
// Add more agents
agents = new Listing {
  agentDeployment("agent-1", 1)
  agentDeployment("agent-2", 1)
  agentDeployment("agent-3", 1)
  agentDeployment("agent-4", 2)  // New agent with 2 replicas
}
```

### Adding New Configuration Outputs

1. Create a new module in `pkl-config/`
2. Import it in `infrastructure.pkl`
3. Add generation logic to `rebuild-configs.sh`

Example for Docker Compose:

```pkl
// pkl-config/docker-compose.pkl
module docker-compose

secrets: Any
paths: Any

version = "3.8"
services = new {
  app = new {
    image = "myapp:latest"
    environment = new {
      AWS_ACCESS_KEY_ID = secrets.aws.access_key_id
    }
  }
}
```

## Security Best Practices

### ⚠️ Never Commit Secrets

The `.gitignore` is configured to exclude:
- `pkl-config/secrets.pkl` - Your actual credentials
- `generated-configs/` - All generated output files

**Always commit:**
- `pkl-config/secrets.pkl.template` - The template structure
- All other `.pkl` modules
- `rebuild-configs.sh` - The build script

### Credential Management

For production environments, consider:
- **AWS Secrets Manager** - Store secrets externally
- **HashiCorp Vault** - Centralized secret management
- **Kubernetes Secrets** - For K8s-native applications
- **Environment-specific secrets.pkl** - `secrets.dev.pkl`, `secrets.prod.pkl`

### Audit Trail

All configuration changes are tracked in git:
```bash
# See who changed what
git log pkl-config/

# Compare configurations
git diff main..feature-branch pkl-config/mcp-servers.pkl
```

## Troubleshooting

### "pkl: command not found"

Pkl is not installed or not in PATH. Install using the Quick Start instructions.

### "secrets.pkl not found"

Copy the template:
```bash
cp pkl-config/secrets.pkl.template pkl-config/secrets.pkl
```

Then edit with your credentials.

### Validation Errors

Pkl performs type checking. Common issues:

```
error: expected type String, got type Int
```

Fix by ensuring types match:
```pkl
// Wrong
port = 8080

// Right
port = "8080"
```

### MCP Servers Not Loading

1. Check paths in `secrets.pkl` are correct
2. Verify generated config: `cat ~/.config/claude_desktop_config.json`
3. Check Claude Desktop logs for errors
4. Ensure executables have proper permissions: `chmod +x /path/to/server`

### AWS Credentials Invalid

1. Verify credentials in `secrets.pkl`
2. Test with AWS CLI: `aws sts get-caller-identity`
3. Check generated credentials: `cat ~/.aws/credentials`
4. Ensure proper IAM permissions for snapshot operations

## Advanced Usage

### Multiple Environments

Create environment-specific secrets:

```bash
pkl-config/
├── secrets.dev.pkl
├── secrets.staging.pkl
└── secrets.prod.pkl
```

Generate for specific environment:
```bash
# Modify rebuild-configs.sh to accept environment argument
./rebuild-configs.sh --env prod
```

### CI/CD Integration

Use Pkl in your CI pipeline:

```yaml
# .github/workflows/validate-config.yml
name: Validate Configurations
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Pkl
        run: |
          curl -L -o /tmp/pkl https://github.com/apple/pkl/releases/download/0.30.0/pkl-linux-amd64
          chmod +x /tmp/pkl
          sudo mv /tmp/pkl /usr/local/bin/pkl
      - name: Validate Pkl modules
        run: |
          pkl eval pkl-config/infrastructure.pkl
          pkl eval pkl-config/mcp-servers.pkl
          pkl eval pkl-config/kubernetes.pkl
```

### Schema Validation

Pkl can validate against schemas:

```pkl
// Validate MCP config against JSON schema
import "package://pkg.pkl-lang.org/pkl-pantry/pkl.json.schema@1.0.0#/JsonSchema.pkl"

mcpSchema = new JsonSchema {
  // Define schema
}

// Validate
assert(mcpServers.conformsTo(mcpSchema))
```

## Benefits Summary

| Before | After (with Pkl) |
|--------|------------------|
| Manual JSON editing | Type-safe Pkl modules |
| Escape sequence errors | Automatic escaping |
| Scattered credentials | Centralized secrets.pkl |
| Config duplication | Single source of truth |
| Manual updates | One-command rebuild |
| No validation | Compile-time type checking |
| Fragile deployments | Reproducible infrastructure |

## Resources

- **Pkl Documentation**: https://pkl-lang.org/
- **Pkl Package Registry**: https://pkl-lang.org/packages
- **Example Projects**: https://github.com/apple/pkl/tree/main/examples

## Next Steps

1. ✅ Install Pkl
2. ✅ Copy and fill `secrets.pkl`
3. ✅ Run `./rebuild-configs.sh`
4. ✅ Test MCP servers in Claude Desktop
5. ✅ Deploy Kubernetes manifests
6. ⏭️ Customize for your infrastructure needs
7. ⏭️ Set up CI/CD validation

---

**Need help?** Check the existing chat history for credential examples or consult the Pkl documentation at https://pkl-lang.org/
