#!/bin/bash

# GitHub Token Configuration Script
# This script helps configure the GitHub Personal Access Token for MCP

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔑 GitHub Token Configuration for MCP${NC}"
echo ""

# Check if configuration files exist
SETTINGS_LOCAL=".claude/settings.local.json"
MCP_JSON=".mcp.json"

if [ ! -f "$SETTINGS_LOCAL" ]; then
    echo -e "${RED}❌ $SETTINGS_LOCAL not found${NC}"
    echo "Please run setup-github-mcp.sh first"
    exit 1
fi

if [ ! -f "$MCP_JSON" ]; then
    echo -e "${RED}❌ $MCP_JSON not found${NC}"
    echo "Please run setup-github-mcp.sh first"
    exit 1
fi

echo "📋 GitHub Personal Access Token Setup:"
echo ""
echo "1. Go to: https://github.com/settings/personal-access-tokens/fine-grained"
echo "2. Click 'Generate new token'"
echo "3. Configure with these permissions:"
echo "   - Contents: Read and write"
echo "   - Metadata: Read"
echo "   - Pull requests: Read and write"
echo "   - Issues: Read and write"
echo "   - Actions: Read"
echo "   - Pages: Read and write"
echo ""

# Prompt for token
echo -e "${YELLOW}Please paste your GitHub Personal Access Token:${NC}"
read -s GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ No token provided${NC}"
    exit 1
fi

# Validate token format (basic check)
if [[ ! "$GITHUB_TOKEN" =~ ^(ghp_|github_pat_) ]]; then
    echo -e "${YELLOW}⚠️  Token doesn't match expected GitHub token format${NC}"
    echo -e "${YELLOW}   GitHub tokens usually start with 'ghp_' or 'github_pat_'${NC}"
    echo ""
    echo -e "${YELLOW}Continue anyway? (y/N):${NC}"
    read -n 1 CONTINUE
    echo ""
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Update settings.local.json
echo -e "${BLUE}📝 Updating $SETTINGS_LOCAL...${NC}"
if command -v jq &> /dev/null; then
    # Use jq if available for proper JSON handling
    jq --arg token "$GITHUB_TOKEN" '.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = $token' "$SETTINGS_LOCAL" > "$SETTINGS_LOCAL.tmp" && mv "$SETTINGS_LOCAL.tmp" "$SETTINGS_LOCAL"
else
    # Fallback to sed (less robust but works)
    sed -i.bak "s/\"GITHUB_PERSONAL_ACCESS_TOKEN\": \"\"/\"GITHUB_PERSONAL_ACCESS_TOKEN\": \"$GITHUB_TOKEN\"/g" "$SETTINGS_LOCAL"
    rm -f "$SETTINGS_LOCAL.bak"
fi

# Update .mcp.json (only if it doesn't contain a token)
echo -e "${BLUE}📝 Updating $MCP_JSON...${NC}"
if command -v jq &> /dev/null; then
    jq --arg token "$GITHUB_TOKEN" '.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = $token' "$MCP_JSON" > "$MCP_JSON.tmp" && mv "$MCP_JSON.tmp" "$MCP_JSON"
else
    sed -i.bak "s/\"GITHUB_PERSONAL_ACCESS_TOKEN\": \"\"/\"GITHUB_PERSONAL_ACCESS_TOKEN\": \"$GITHUB_TOKEN\"/g" "$MCP_JSON"
    rm -f "$MCP_JSON.bak"
fi

echo -e "${GREEN}✅ Token configured successfully!${NC}"
echo ""
echo -e "${YELLOW}🔒 Security Notes:${NC}"
echo "• $SETTINGS_LOCAL is in .gitignore (not committed)"
echo "• $MCP_JSON contains your token - be careful with Git commits"
echo "• Consider using environment variables for production"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Restart Claude Code"
echo "2. Test with: 'List my GitHub repositories'"
echo "3. Try: 'Create a new repository for Luigi Knowledge Extractor'"
echo ""

# Check if Claude Code is running
if pgrep -x "claude" > /dev/null; then
    echo -e "${YELLOW}⚠️  Claude Code is currently running${NC}"
    echo -e "${YELLOW}   Please restart it for changes to take effect${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Configuration complete!${NC}"