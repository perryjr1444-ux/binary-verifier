# Quick Start: Rebuild Your Infrastructure in 5 Minutes

## Fresh OS Installation Recovery

You're on a fresh OS install and need everything back. Here's the fastest path:

### Step 1: Install Pkl (2 minutes)

```bash
# Linux
curl -L -o /tmp/pkl https://github.com/apple/pkl/releases/download/0.30.0/pkl-linux-amd64
chmod +x /tmp/pkl
sudo mv /tmp/pkl /usr/local/bin/pkl

# macOS
brew install pkl

# Verify
pkl --version
```

### Step 2: Configure Secrets (2 minutes)

```bash
# Navigate to repo
cd /path/to/binary-verifier

# Copy template
cp pkl-config/secrets.pkl.template pkl-config/secrets.pkl

# Edit with YOUR credentials
nano pkl-config/secrets.pkl
```

**What to fill in:**

```pkl
aws: AWS = new {
  access_key_id = "AKIA..."              // Your AWS access key
  secret_access_key = "..."               // Your AWS secret key
  region = "us-east-1"                    // Your AWS region
  snapshot_role_arn = "arn:aws:iam::..." // Your snapshot role ARN
}

mcp: MCP = new {
  mantis_crystals_key = "..."            // Path to Mantis crystals key
  mobile_bridge_token = "..."            // Mobile bridge auth token
}

kubernetes: K8s = new {
  cluster_endpoint = "https://..."       // Your K8s API endpoint
  api_token = "..."                       // K8s service account token
  namespace = "default"                   // Target namespace
}

github: GitHub = new {
  personal_access_token = "ghp_..."      // GitHub PAT
  username = "perryjr1444-ux"            // Your GitHub username
}
```

### Step 3: Regenerate Everything (1 minute)

```bash
# Run the magic script
./rebuild-configs.sh
```

**This generates:**
- ✅ `~/.config/claude_desktop_config.json` - All MCP servers configured
- ✅ `~/.aws/credentials` - AWS access configured
- ✅ `~/.aws/config` - AWS regions and profiles
- ✅ `generated-configs/.env` - All environment variables
- ✅ `generated-configs/k8s-*.yaml` - Kubernetes manifests

### Step 4: Activate (30 seconds)

```bash
# Source environment
source generated-configs/.env

# Apply Kubernetes (if using)
kubectl apply -f generated-configs/k8s-namespace.yaml
kubectl apply -f generated-configs/k8s-agents.yaml
kubectl apply -f generated-configs/k8s-service.yaml

# Restart Claude Desktop
# macOS: Cmd+Q and reopen
# Linux: killall claude-desktop && claude-desktop &
```

## You're Done! 🎉

All your infrastructure is back:
- Claude Desktop has all MCP servers
- AWS CLI is configured
- Kubernetes agents are deployed
- Environment is set up

## Looking for AWS/MCP Credentials from Chat History?

**I don't have access to previous chat history** - each session is isolated.

**Where to find them:**

1. **AWS Console**:
   - IAM → Users → Your user → Security credentials
   - Create new access key if needed

2. **Mantis Crystals Key**:
   - Check your secure storage or password manager
   - Path is usually `~/.mantis/crystals.key`

3. **Mobile Bridge Token**:
   - Regenerate from mobile bridge admin panel
   - Or check your previous installation notes

4. **Kubernetes Token**:
   ```bash
   kubectl get secret <service-account-secret> -o jsonpath='{.data.token}' | base64 -d
   ```

5. **GitHub PAT**:
   - GitHub → Settings → Developer settings → Personal access tokens
   - Generate new token if needed

## Troubleshooting

**"pkl: command not found"**
- Pkl not installed - follow Step 1

**"secrets.pkl not found"**
- Haven't copied template - follow Step 2

**"AWS credentials invalid"**
- Double-check access key and secret in `secrets.pkl`
- Test: `aws sts get-caller-identity`

**"MCP servers not loading"**
- Check paths exist: `ls -la ~/projects/mantis-mcp-server`
- Verify permissions: `chmod +x ~/projects/mantis-mcp-server/mantis-mcp`
- Check Claude Desktop logs

## Next Steps

- Customize `pkl-config/mcp-servers.pkl` for your setup
- Add more agents in `pkl-config/kubernetes.pkl`
- Set up CI/CD validation (see PKL_INFRASTRUCTURE.md)

For full documentation: **Read PKL_INFRASTRUCTURE.md**
