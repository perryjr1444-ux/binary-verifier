# Fresh OS Installation - Credential Setup Checklist

You're starting from scratch. Here's your step-by-step plan to get all credentials.

## Priority Order (Do These First)

### ✅ 1. GitHub Personal Access Token (5 min) - DO THIS FIRST
**Why first:** You'll need this for git operations and it's the easiest.

**Steps:**
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Name it: "Fresh OS - Binary Verifier Setup"
4. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Actions workflows)
5. Click "Generate token"
6. **COPY IT IMMEDIATELY** (GitHub only shows it once!)

**Paste into secrets.pkl:**
```pkl
github: GitHub = new {
  personal_access_token = "ghp_xxxxx..."  // Paste here
  username = "perryjr1444-ux"
}
```

---

### ✅ 2. AWS Credentials (10 min)

**You need:**
- AWS account (create at https://aws.amazon.com if you don't have one)
- Access to AWS Console

**Steps:**

#### A. Get Access Key & Secret Key
1. Log into AWS Console: https://console.aws.amazon.com/
2. Go to: **IAM** → **Users** → **perryjr1444-ux** (or create user if needed)
3. Click **Security credentials** tab
4. Under **Access keys**, click **Create access key**
5. Choose use case: "Command Line Interface (CLI)"
6. Acknowledge checkbox, click "Next"
7. Add description: "Binary Verifier Fresh OS"
8. Click "Create access key"
9. **SAVE BOTH VALUES:**
   - Access key ID (starts with `AKIA`)
   - Secret access key (long random string)

#### B. Choose Region
Pick the AWS region closest to you:
- `us-east-1` (Virginia) - Most common, cheapest
- `us-west-2` (Oregon)
- `eu-west-1` (Ireland)
- `ap-southeast-1` (Singapore)

#### C. Create Snapshot Role (if doing EBS snapshots)
```bash
# After getting AWS credentials, run:
aws configure  # Enter your access key, secret key, region

# Create role
aws iam create-role --role-name SnapshotManagerRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::YOUR_ACCOUNT_ID:root"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach policy
aws iam attach-role-policy --role-name SnapshotManagerRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess

# Get role ARN (copy this)
aws iam get-role --role-name SnapshotManagerRole --query 'Role.Arn' --output text
```

**Paste into secrets.pkl:**
```pkl
aws: AWS = new {
  access_key_id = "AKIAIOSFODNN7EXAMPLE"  // From step A
  secret_access_key = "wJalr..."          // From step A
  region = "us-east-1"                     // From step B
  snapshot_role_arn = "arn:aws:iam::..."  // From step C
}
```

**If you don't need snapshots:** Use any placeholder for `snapshot_role_arn`

---

### ⚠️ 3. MCP Server Credentials (OPTIONAL - Only if using)

#### Do you actually need these?
- **Mantis MCP Server** - Only if you have the mantis-mcp-server project
- **Mobile Bridge** - Only if you're doing iOS/Android integration

**If you DON'T have these projects, you can:**
1. **Skip them** - Comment out in `mcp-servers.pkl`
2. **Use placeholders** - They won't be used if MCP servers aren't installed

#### If you DO need them:

**Mantis Crystals Key:**
```bash
# Check if you have mantis-mcp-server installed
ls -la ~/projects/mantis-mcp-server

# If yes, generate key
cd ~/projects/mantis-mcp-server
./generate-crystals-key.sh  # Or equivalent setup command

# Key is usually saved to:
# ~/.mantis/crystals.key
```

**Mobile Bridge Token:**
```bash
# Check if you have mobile-bridge installed
ls -la ~/projects/mobile-bridge

# If yes, generate token
cd ~/projects/mobile-bridge
./generate-token.sh  # Or equivalent setup command
```

**Paste into secrets.pkl:**
```pkl
mcp: MCP = new {
  mantis_crystals_key = "/home/user/.mantis/crystals.key"  // Path to key file
  mobile_bridge_token = "mb_xxxxx..."                       // Generated token
}
```

---

### ⚠️ 4. Kubernetes Credentials (OPTIONAL - Only if using K8s)

#### Do you have a Kubernetes cluster?
- **Yes** → Follow steps below
- **No** → Use placeholders or skip

#### If YES:

**Get Cluster Endpoint:**
```bash
# From existing kubeconfig
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

# Or from cloud provider:
# - AWS EKS: Console → EKS → Clusters → Your cluster → API endpoint
# - GKE: Console → Kubernetes Engine → Clusters → Endpoint
```

**Get API Token:**
```bash
# Option 1: Extract from existing kubeconfig
kubectl config view --raw -o jsonpath='{.users[0].user.token}'

# Option 2: Create new service account
kubectl create serviceaccount claude-agent
kubectl create clusterrolebinding claude-agent-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=default:claude-agent

# Get token
kubectl get secret $(kubectl get serviceaccount claude-agent -o jsonpath='{.secrets[0].name}') \
  -o jsonpath='{.data.token}' | base64 -d
```

**Paste into secrets.pkl:**
```pkl
kubernetes: K8s = new {
  cluster_endpoint = "https://ABC123.gr7.us-east-1.eks.amazonaws.com"
  api_token = "eyJhbGci..."
  namespace = "default"
}
```

---

## Minimal Working Configuration

**If you only want AWS + GitHub** (most common), here's what you need:

```pkl
module secrets

aws: AWS = new {
  access_key_id = "AKIA..."      // From AWS Console
  secret_access_key = "..."       // From AWS Console
  region = "us-east-1"            // Your choice
  snapshot_role_arn = "arn:aws:iam::123456789012:role/SnapshotManagerRole"
}

mcp: MCP = new {
  mantis_crystals_key = "/home/user/.mantis/crystals.key"  // Placeholder
  mobile_bridge_token = "placeholder_token"                 // Placeholder
}

kubernetes: K8s = new {
  cluster_endpoint = "https://placeholder.k8s.local"  // Placeholder
  api_token = "placeholder_token"                      // Placeholder
  namespace = "default"
}

github: GitHub = new {
  personal_access_token = "ghp_..."  // From GitHub
  username = "perryjr1444-ux"
}

// (Type definitions remain the same)
```

Then comment out unused MCP servers in `pkl-config/mcp-servers.pkl`.

---

## Progress Tracker

Use this to track what you've completed:

```
[ ] 1. GitHub PAT generated
[ ] 2. AWS access key created
[ ] 3. AWS secret key saved
[ ] 4. AWS region chosen
[ ] 5. AWS snapshot role created (or placeholdered)
[ ] 6. Mantis key path set (or placeholdered)
[ ] 7. Mobile bridge token set (or placeholdered)
[ ] 8. K8s endpoint found (or placeholdered)
[ ] 9. K8s token extracted (or placeholdered)
[ ] 10. All values pasted into pkl-config/secrets.pkl
[ ] 11. Run: ./rebuild-configs.sh
[ ] 12. Test: source generated-configs/.env
```

---

## Quick Test Commands

After you've filled in credentials and run `./rebuild-configs.sh`:

```bash
# Test AWS
aws sts get-caller-identity

# Test generated files exist
ls -la ~/.config/claude_desktop_config.json
ls -la ~/.aws/credentials
ls -la generated-configs/

# Test environment
source generated-configs/.env
echo $AWS_ACCESS_KEY_ID
```

---

## Need Help?

**Stuck on a specific step?** Tell me which credential you're trying to get and I'll provide detailed help.

**Don't need certain services?** Tell me which ones you actually use and I'll help you create a minimal configuration.
