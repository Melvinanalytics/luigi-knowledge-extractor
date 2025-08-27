# GitHub MCP Setup for Luigi Knowledge Extractor

This document provides complete instructions for setting up GitHub MCP (Model Context Protocol) integration with Claude Code to enable seamless GitHub operations.

## Prerequisites

- Claude Code installed and running
- Node.js and npm installed on your system
- GitHub account with repository access

## 1. GitHub Personal Access Token Setup

### Create GitHub Personal Access Token

1. Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/personal-access-tokens/fine-grained)
2. Click "Generate new token" > "Fine-grained personal access token"
3. Configure the token with these permissions:

**Repository permissions:**
- Contents: Read and write
- Metadata: Read
- Pull requests: Read and write
- Issues: Read and write
- Actions: Read (for CI/CD)
- Pages: Read and write (for deployment)

**Account permissions:**
- Git SSH keys: Read (if using SSH)

4. Set expiration (recommend 90 days for security)
5. Click "Generate token"
6. **Important:** Copy the token immediately - you won't see it again!

### Set Token in Configuration

Update the token in both configuration files:

**File: `.claude/settings.local.json`**
```json
{
  "mcpServers": {
    "github": {
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_ACTUAL_TOKEN_HERE"
      }
    }
  }
}
```

**File: `.mcp.json`**
```json
{
  "mcpServers": {
    "github": {
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_ACTUAL_TOKEN_HERE"
      }
    }
  }
}
```

## 2. MCP Server Installation

The MCP servers will be automatically installed when Claude Code starts. However, you can pre-install them:

```bash
# Install GitHub MCP Server
npm install -g @modelcontextprotocol/server-github

# Install Git MCP Server (for local Git operations)
npm install -g @modelcontextprotocol/server-git

# Install Filesystem MCP Server (for file operations)
npm install -g @modelcontextprotocol/server-filesystem
```

## 3. Configuration Files Explanation

### `.claude/settings.local.json`
- Project-specific configuration
- **Not committed to Git** (contains sensitive tokens)
- Only applies to this project

### `.mcp.json`
- Shareable project configuration
- Can be committed to Git (without sensitive data)
- Available to all team members

## 4. Available GitHub Operations

Once configured, you can perform these operations through Claude Code:

### Repository Management
- Create new repositories
- Clone repositories
- List repositories
- Get repository information

### File Operations
- Create/update files in repositories
- Read file contents
- Delete files
- Batch file operations

### Branch Management
- Create branches
- Switch branches
- List branches
- Merge branches

### Pull Request Operations
- Create pull requests
- List pull requests
- Update pull requests
- Review pull requests

### Issue Management
- Create issues
- List issues
- Update issues
- Close issues

### Search Operations
- Search code
- Search repositories
- Search users
- Search issues/PRs

## 5. Restart Claude Code

After configuration, restart Claude Code:

```bash
# If running in terminal
Ctrl+C to stop
claude code

# Or restart the application if using GUI
```

## 6. Verification

Test the setup by asking Claude Code:

```
"List my GitHub repositories"
"Create a new repository called 'test-repo'"
"Show me the README.md file from my luigi-extractor repository"
```

## 7. Security Best Practices

### Token Security
- Use fine-grained tokens with minimal required permissions
- Set reasonable expiration dates (30-90 days)
- Regularly rotate tokens
- Never commit tokens to Git

### Configuration Security
- Keep `.claude/settings.local.json` in `.gitignore`
- Use environment variables for CI/CD pipelines
- Regularly audit MCP server permissions

## 8. Troubleshooting

### Common Issues

**MCP Server Not Found**
```bash
# Check if servers are installed
npm list -g @modelcontextprotocol/server-github

# Reinstall if missing
npm install -g @modelcontextprotocol/server-github
```

**Authentication Errors**
- Verify token has correct permissions
- Check token hasn't expired
- Ensure token is correctly set in configuration

**Debug Mode**
```bash
# Start Claude Code with MCP debugging
claude code --mcp-debug
```

### Log Files
Check Claude Code logs for MCP server issues:
- macOS: `~/Library/Logs/Claude Code/`
- Linux: `~/.local/share/claude-code/logs/`
- Windows: `%APPDATA%\claude-code\logs\`

## 9. Team Collaboration

### Sharing Configuration
1. Add `.mcp.json` to your Git repository
2. Update `.gitignore` to exclude sensitive files:

```gitignore
# Claude Code sensitive configuration
.claude/settings.local.json
.claude/*.local.json

# Allow shared configuration
!.mcp.json
```

3. Team members need to:
   - Create their own GitHub Personal Access Token
   - Update their local `.claude/settings.local.json`
   - Restart Claude Code

## 10. Deployment Integration

### Railway.app Integration
With GitHub MCP configured, you can:

1. Push code to GitHub repository
2. Connect Railway.app to the GitHub repository
3. Configure automatic deployments
4. Manage deployments through GitHub operations

Example workflow:
```
1. "Create a new branch called 'deployment-ready'"
2. "Push all changes to the deployment-ready branch"
3. "Create a pull request from deployment-ready to main"
4. "After review, merge the pull request"
```

## 11. Advanced Configuration

### Custom MCP Servers
Add additional MCP servers for extended functionality:

```json
{
  "mcpServers": {
    "railway": {
      "command": "npx",
      "args": ["-y", "@your-org/railway-mcp-server"],
      "env": {
        "RAILWAY_TOKEN": ""
      }
    }
  }
}
```

### Environment-Specific Configuration
Use different configurations for development/production:

```json
{
  "mcpServers": {
    "github-dev": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_DEV_TOKEN}",
        "GITHUB_API_URL": "https://api.github.com"
      }
    }
  }
}
```

## Support

For additional help:
- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [GitHub MCP Server Repository](https://github.com/modelcontextprotocol/servers)
- [Claude Code Documentation](https://docs.anthropic.com/claude-code)

---

**Last Updated:** August 2025
**Version:** 1.0
**Compatible with:** Claude Code, MCP 2025.4.8+