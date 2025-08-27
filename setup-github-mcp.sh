#!/bin/bash

# GitHub MCP Setup Script for Luigi Knowledge Extractor
# This script sets up GitHub MCP integration for Claude Code

set -e

echo "🚀 Setting up GitHub MCP for Luigi Knowledge Extractor..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js first.${NC}"
    echo "Visit: https://nodejs.org/"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed. Please install npm first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js and npm are installed${NC}"

# Create .claude directory if it doesn't exist
if [ ! -d ".claude" ]; then
    mkdir -p .claude
    echo -e "${GREEN}✅ Created .claude directory${NC}"
fi

# Install MCP servers globally
echo -e "${BLUE}📦 Installing MCP servers...${NC}"

npm install -g @modelcontextprotocol/server-github
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ GitHub MCP server installed${NC}"
else
    echo -e "${RED}❌ Failed to install GitHub MCP server${NC}"
    exit 1
fi

npm install -g @modelcontextprotocol/server-git
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Git MCP server installed${NC}"
else
    echo -e "${RED}❌ Failed to install Git MCP server${NC}"
    exit 1
fi

npm install -g @modelcontextprotocol/server-filesystem
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Filesystem MCP server installed${NC}"
else
    echo -e "${RED}❌ Failed to install Filesystem MCP server${NC}"
    exit 1
fi

# Verify installations
echo -e "${BLUE}🔍 Verifying installations...${NC}"

if npm list -g @modelcontextprotocol/server-github &> /dev/null; then
    echo -e "${GREEN}✅ GitHub MCP server verified${NC}"
else
    echo -e "${YELLOW}⚠️  GitHub MCP server may not be installed correctly${NC}"
fi

if npm list -g @modelcontextprotocol/server-git &> /dev/null; then
    echo -e "${GREEN}✅ Git MCP server verified${NC}"
else
    echo -e "${YELLOW}⚠️  Git MCP server may not be installed correctly${NC}"
fi

if npm list -g @modelcontextprotocol/server-filesystem &> /dev/null; then
    echo -e "${GREEN}✅ Filesystem MCP server verified${NC}"
else
    echo -e "${YELLOW}⚠️  Filesystem MCP server may not be installed correctly${NC}"
fi

echo ""
echo -e "${GREEN}🎉 MCP servers installation complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Create a GitHub Personal Access Token:"
echo "   → Go to: https://github.com/settings/personal-access-tokens/fine-grained"
echo "   → Generate a new token with repository permissions"
echo ""
echo "2. Update your GitHub token in the configuration files:"
echo "   → .claude/settings.local.json"
echo "   → .mcp.json"
echo ""
echo "3. Restart Claude Code for changes to take effect"
echo ""
echo "4. Test with: 'List my GitHub repositories'"
echo ""
echo -e "${BLUE}📚 For detailed instructions, see: GITHUB_MCP_SETUP.md${NC}"

# Check if Claude Code is running
if pgrep -x "claude" > /dev/null; then
    echo ""
    echo -e "${YELLOW}⚠️  Claude Code is currently running${NC}"
    echo -e "${YELLOW}   Please restart it after configuring your GitHub token${NC}"
fi

echo ""
echo -e "${GREEN}✨ Setup complete! Happy coding!${NC}"