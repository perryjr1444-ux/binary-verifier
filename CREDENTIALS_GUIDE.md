# Credentials Guide: Where to Find Everything

## AWS Credentials

### Access Key ID and Secret Access Key

**Where to get them:**

1. Log into AWS Console: https://console.aws.amazon.com/
2. Navigate to: **IAM** → **Users** → **Your Username**
3. Click **Security credentials** tab
4. Under **Access keys**, click **Create access key**
5. Choose **Use case**: "Command Line Interface (CLI)"
6. Copy the **Access key ID** and **Secret access key**

**Format:**
```
access_key_id = "AKIAIOSFODNN7EXAMPLE"
secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

### Snapshot Role ARN

**What it is:** IAM role for EBS snapshot operations

**Where to get it:**

1. AWS Console → **IAM** → **Roles**
2. Find your snapshot role (or create one with `ec2:CreateSnapshot`, `ec2:DescribeSnapshots` permissions)
3. Copy the **Role ARN** from the role summary

**Format:**
```
snapshot_role_arn = "arn:aws:iam::123456789012:role/SnapshotManagerRole"
```

**If you don't have one:**
```bash
# Create via AWS CLI
aws iam create-role --role-name SnapshotManagerRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach snapshot policy
aws iam attach-role-policy --role-name SnapshotManagerRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess
```

### Region

**Most common:**
- `us-east-1` (US East - N. Virginia)
- `us-west-2` (US West - Oregon)
- `eu-west-1` (Europe - Ireland)
- `ap-southeast-1` (Asia Pacific - Singapore)

**Check your current region:**
```bash
aws configure get region
```

---

## MCP Credentials

### Mantis Crystals Key

**What it is:** Post-quantum cryptographic key for Mantis MCP server

**Where to find it:**

1. Check your home directory: `~/.mantis/crystals.key`
2. Or your secure notes/password manager under "Mantis MCP"
3. If lost, regenerate from Mantis MCP server setup:
   ```bash
   cd ~/projects/mantis-mcp-server
   ./generate-crystals-key.sh
   ```

**Format in secrets.pkl:**
```pkl
mantis_crystals_key = "/home/user/.mantis/crystals.key"  // Path to key file
```

**Note:** This should be a **path**, not the key contents itself.

### Mobile Bridge Token

**What it is:** Authentication token for iOS/Android bridge

**Where to find it:**

1. Check your mobile bridge admin dashboard
2. Or your password manager under "Mobile Bridge"
3. If lost, regenerate:
   ```bash
   cd ~/projects/mobile-bridge
   ./generate-token.sh
   ```

**Format:**
```pkl
mobile_bridge_token = "mb_1234567890abcdefghijklmnopqrstuvwxyz"
```

---

## Kubernetes Credentials

### Cluster Endpoint

**What it is:** Your Kubernetes API server URL

**Where to find it:**

1. From your kubeconfig:
   ```bash
   kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
   ```

2. Or from your cloud provider:
   - **AWS EKS**: EKS Console → Clusters → Your Cluster → API server endpoint
   - **GKE**: GKE Console → Clusters → Your Cluster → Endpoint
   - **Azure AKS**: AKS Console → Your Cluster → Properties → Kubernetes API server address

**Format:**
```pkl
cluster_endpoint = "https://ABC123.gr7.us-east-1.eks.amazonaws.com"
```

### API Token

**What it is:** Service account token for authentication

**Where to get it:**

1. Get service account secret name:
   ```bash
   kubectl get serviceaccounts -n default
   kubectl get secret
   ```

2. Extract token:
   ```bash
   kubectl get secret <service-account-secret-name> -o jsonpath='{.data.token}' | base64 -d
   ```

3. Or create a new service account:
   ```bash
   kubectl create serviceaccount claude-agent
   kubectl create clusterrolebinding claude-agent-admin \
     --clusterrole=cluster-admin \
     --serviceaccount=default:claude-agent
   kubectl get secret $(kubectl get serviceaccount claude-agent -o jsonpath='{.secrets[0].name}') \
     -o jsonpath='{.data.token}' | base64 -d
   ```

**Format:**
```pkl
api_token = "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij..."  // Very long token string
```

### Namespace

**What it is:** Kubernetes namespace for your deployments

**Common values:**
- `default` - Default namespace
- `production` - Production workloads
- `staging` - Staging environment
- `autosecure` - Custom namespace for AutoSecure Platform

**Format:**
```pkl
namespace = "default"
```

---

## GitHub Credentials

### Personal Access Token (PAT)

**What it is:** Token for GitHub API access

**Where to get it:**

1. GitHub → **Settings** (your profile)
2. **Developer settings** → **Personal access tokens** → **Tokens (classic)**
3. **Generate new token (classic)**
4. Select scopes:
   - ✅ `repo` - Full control of private repositories
   - ✅ `workflow` - Update GitHub Actions workflows
   - ✅ `read:org` - Read org and team membership
5. Generate and copy the token

**Format:**
```pkl
personal_access_token = "ghp_1234567890abcdefghijklmnopqrstuvwxyz1234"
```

**⚠️ Important:** Save this immediately - GitHub only shows it once!

---

## Complete Example: secrets.pkl

Here's what your filled-in `secrets.pkl` should look like:

```pkl
module secrets

/// AWS Credentials
aws: AWS = new {
  access_key_id = "AKIAIOSFODNN7EXAMPLE"
  secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  region = "us-east-1"
  snapshot_role_arn = "arn:aws:iam::123456789012:role/SnapshotManagerRole"
}

/// MCP Server Credentials
mcp: MCP = new {
  mantis_crystals_key = "/home/user/.mantis/crystals.key"
  mobile_bridge_token = "mb_1234567890abcdefghijklmnopqrstuvwxyz"
}

/// Kubernetes Credentials
kubernetes: K8s = new {
  cluster_endpoint = "https://ABC123.gr7.us-east-1.eks.amazonaws.com"
  api_token = "eyJhbGciOiJSUzI1NiIsImtpZCI6IkR..."
  namespace = "default"
}

/// GitHub Credentials
github: GitHub = new {
  personal_access_token = "ghp_1234567890abcdefghijklmnopqrstuvwxyz1234"
  username = "perryjr1444-ux"
}

/// Type definitions (leave these as-is)
typealias AWS = {
  access_key_id: String
  secret_access_key: String
  region: String
  snapshot_role_arn: String
}

typealias MCP = {
  mantis_crystals_key: String
  mobile_bridge_token: String
}

typealias K8s = {
  cluster_endpoint: String
  api_token: String
  namespace: String
}

typealias GitHub = {
  personal_access_token: String
  username: String
}
```

---

## Security Best Practices

### ✅ DO:
- Store `secrets.pkl` securely (it's gitignored)
- Use a password manager for backup
- Rotate credentials regularly
- Use IAM roles with least privilege
- Enable MFA on AWS account

### ❌ DON'T:
- Commit `secrets.pkl` to git
- Share credentials in chat/email
- Use root AWS credentials
- Store credentials in code
- Reuse credentials across environments

---

## Testing Your Credentials

### Test AWS:
```bash
source generated-configs/.env
aws sts get-caller-identity
```

### Test Kubernetes:
```bash
kubectl get nodes
kubectl get pods -n default
```

### Test MCP Servers:
```bash
# Check Claude Desktop config was generated
cat ~/.config/claude_desktop_config.json

# Restart Claude Desktop and check MCP servers load
```

---

## Troubleshooting

**"Invalid AWS credentials"**
- Verify access key starts with `AKIA`
- Check for extra spaces or quotes
- Test with: `aws sts get-caller-identity`

**"Kubernetes unauthorized"**
- Token may be expired - regenerate
- Check service account has proper RBAC permissions
- Verify cluster endpoint is correct

**"Mantis key not found"**
- Check file path is absolute, not relative
- Verify file exists: `ls -la ~/.mantis/crystals.key`
- Ensure proper permissions: `chmod 600 ~/.mantis/crystals.key`

**"GitHub token invalid"**
- Token may be expired or revoked
- Generate new token with correct scopes
- Verify token starts with `ghp_`

---

## Need Help?

If you're stuck, paste your **non-sensitive** configuration structure (with credentials redacted) and I can help debug.

**Safe to share:**
- File paths
- AWS region names
- Kubernetes namespace names
- Error messages

**Never share:**
- Access keys or secrets
- API tokens
- Private keys
- Actual credential values
