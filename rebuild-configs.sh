#!/bin/bash
# Infrastructure Configuration Builder
# Regenerates all configuration files from Pkl sources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
PKL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/pkl-config" && pwd)"
OUTPUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/generated-configs" && pwd)"
HOME_DIR="${HOME}"

# Check if Pkl is installed
check_pkl() {
    if ! command -v pkl &> /dev/null; then
        echo -e "${RED}ERROR: pkl not found in PATH${NC}"
        echo -e "${YELLOW}Install pkl first:${NC}"
        echo "  curl -L -o /tmp/pkl-installer.sh https://github.com/apple/pkl/releases/download/0.30.0/pkl-linux-amd64"
        echo "  chmod +x /tmp/pkl-installer.sh"
        echo "  sudo mv /tmp/pkl-installer.sh /usr/local/bin/pkl"
        echo ""
        echo "Or use the official installer from: https://pkl-lang.org/main/current/pkl-cli/index.html#installation"
        exit 1
    fi
    echo -e "${GREEN}✓ pkl found: $(pkl --version)${NC}"
}

# Check if secrets.pkl exists
check_secrets() {
    if [ ! -f "${PKL_DIR}/secrets.pkl" ]; then
        echo -e "${RED}ERROR: secrets.pkl not found${NC}"
        echo -e "${YELLOW}Create it from the template:${NC}"
        echo "  cp ${PKL_DIR}/secrets.pkl.template ${PKL_DIR}/secrets.pkl"
        echo "  # Then edit secrets.pkl with your actual credentials"
        exit 1
    fi
    echo -e "${GREEN}✓ secrets.pkl found${NC}"
}

# Create necessary directories
create_dirs() {
    echo -e "${BLUE}Creating directories...${NC}"
    mkdir -p "${OUTPUT_DIR}"
    mkdir -p "${HOME_DIR}/.config"
    mkdir -p "${HOME_DIR}/.aws"
    mkdir -p "${HOME_DIR}/.kube"
    mkdir -p "${HOME_DIR}/.mantis"
    mkdir -p "${HOME_DIR}/projects"
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Generate Claude Desktop MCP config
generate_mcp_config() {
    echo -e "${BLUE}Generating Claude Desktop MCP config...${NC}"
    pkl eval -f json "${PKL_DIR}/mcp-servers.pkl" -p output > "${OUTPUT_DIR}/claude_desktop_config.json"

    # Also copy to actual location
    cp "${OUTPUT_DIR}/claude_desktop_config.json" "${HOME_DIR}/.config/claude_desktop_config.json"
    echo -e "${GREEN}✓ Generated: claude_desktop_config.json${NC}"
}

# Generate AWS config files
generate_aws_config() {
    echo -e "${BLUE}Generating AWS configurations...${NC}"

    # Generate credentials
    pkl eval -f json "${PKL_DIR}/aws-config.pkl" -p credentials > "${OUTPUT_DIR}/aws_credentials.json"
    pkl eval "${PKL_DIR}/aws-config.pkl" -x renderCredentials > "${OUTPUT_DIR}/aws_credentials"
    cp "${OUTPUT_DIR}/aws_credentials" "${HOME_DIR}/.aws/credentials"

    # Generate config
    pkl eval -f json "${PKL_DIR}/aws-config.pkl" -p config > "${OUTPUT_DIR}/aws_config.json"
    pkl eval "${PKL_DIR}/aws-config.pkl" -x renderConfig > "${OUTPUT_DIR}/aws_config"
    cp "${OUTPUT_DIR}/aws_config" "${HOME_DIR}/.aws/config"

    echo -e "${GREEN}✓ Generated: AWS credentials and config${NC}"
}

# Generate environment file
generate_env_file() {
    echo -e "${BLUE}Generating environment file...${NC}"
    pkl eval -f json "${PKL_DIR}/infrastructure.pkl" -p environment > "${OUTPUT_DIR}/environment.json"

    # Convert JSON to .env format
    python3 -c "
import json
import sys

with open('${OUTPUT_DIR}/environment.json', 'r') as f:
    env = json.load(f)

with open('${OUTPUT_DIR}/.env', 'w') as f:
    for key, value in env.items():
        f.write(f'{key}=\"{value}\"\n')
" 2>/dev/null || {
        # Fallback if python not available
        echo "# Auto-generated environment file" > "${OUTPUT_DIR}/.env"
        echo "# Source this file: source generated-configs/.env" >> "${OUTPUT_DIR}/.env"
    }

    echo -e "${GREEN}✓ Generated: .env file${NC}"
}

# Generate Kubernetes manifests
generate_k8s_manifests() {
    echo -e "${BLUE}Generating Kubernetes manifests...${NC}"

    # Generate namespace
    pkl eval -f yaml "${PKL_DIR}/kubernetes.pkl" -p namespace > "${OUTPUT_DIR}/k8s-namespace.yaml"

    # Generate agent deployments
    pkl eval -f yaml "${PKL_DIR}/kubernetes.pkl" -p agents > "${OUTPUT_DIR}/k8s-agents.yaml"

    # Generate service
    pkl eval -f yaml "${PKL_DIR}/kubernetes.pkl" -p service > "${OUTPUT_DIR}/k8s-service.yaml"

    echo -e "${GREEN}✓ Generated: Kubernetes manifests${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Infrastructure Configuration Builder${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""

    check_pkl
    check_secrets
    create_dirs

    echo ""
    echo -e "${BLUE}Generating configuration files...${NC}"
    echo ""

    generate_mcp_config
    generate_aws_config
    generate_env_file
    generate_k8s_manifests

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ All configurations generated!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Generated files in:${NC}"
    echo "  ${OUTPUT_DIR}/"
    echo ""
    echo -e "${YELLOW}Installed to:${NC}"
    echo "  ${HOME_DIR}/.config/claude_desktop_config.json"
    echo "  ${HOME_DIR}/.aws/credentials"
    echo "  ${HOME_DIR}/.aws/config"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Source the environment: source ${OUTPUT_DIR}/.env"
    echo "  2. Apply K8s manifests: kubectl apply -f ${OUTPUT_DIR}/k8s-*.yaml"
    echo "  3. Restart Claude Desktop to load MCP servers"
    echo ""
}

# Run main function
main "$@"
