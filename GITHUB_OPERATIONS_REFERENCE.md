# GitHub Operations Reference Card

Quick reference for GitHub operations available through Claude Code with MCP integration.

## 🏗️ Repository Management

### Create Repository
```
"Create a new GitHub repository called 'luigi-knowledge-extractor'"
"Create a public repository for the Luigi project with description 'AI-powered knowledge extraction system'"
```

### List Repositories
```
"List my GitHub repositories"
"Show me all repositories I own"
"Display my recent repositories"
```

### Get Repository Information
```
"Show information about the luigi-extractor repository"
"Get details for repository owner/repo-name"
```

### Clone Repository
```
"Clone the luigi-extractor repository"
"Clone https://github.com/username/luigi-extractor.git"
```

## 📁 File Operations

### Create/Update Files
```
"Create a README.md file in my luigi-extractor repository"
"Update the Dockerfile in the main branch"
"Add a new file called deploy.yml to the .github/workflows directory"
```

### Read Files
```
"Show me the contents of README.md from luigi-extractor"
"Read the package.json file from the repository"
```

### Delete Files
```
"Delete the old-file.rb from the repository"
"Remove unused files from the config directory"
```

### Batch Operations
```
"Update multiple files in the repository: README.md, Dockerfile, and config/database.yml"
"Create several new files for the deployment configuration"
```

## 🌿 Branch Management

### Create Branches
```
"Create a new branch called 'feature/railway-deployment'"
"Create a deployment-ready branch from main"
```

### List Branches
```
"Show all branches in the luigi-extractor repository"
"List remote branches"
```

### Switch Branches
```
"Switch to the deployment branch"
"Checkout the feature/railway-deployment branch"
```

### Merge Branches
```
"Merge the feature branch into main"
"Create a pull request to merge deployment-ready into main"
```

## 🔄 Pull Request Operations

### Create Pull Requests
```
"Create a pull request from deployment-ready to main"
"Create a PR with title 'Add Railway deployment configuration'"
```

### List Pull Requests
```
"Show open pull requests for luigi-extractor"
"List all PRs in the repository"
```

### Update Pull Requests
```
"Update the pull request #5 with new changes"
"Add a comment to pull request #3"
```

### Review Pull Requests
```
"Show reviews for pull request #2"
"Get the review comments for the latest PR"
```

## 🎯 Issue Management

### Create Issues
```
"Create an issue titled 'Add Docker support for Railway deployment'"
"Create a bug report for the knowledge extraction service"
```

### List Issues
```
"Show open issues in luigi-extractor"
"List all issues assigned to me"
```

### Update Issues
```
"Close issue #10"
"Add a comment to issue #5 with deployment status"
```

## 🔍 Search Operations

### Search Code
```
"Search for 'KnowledgeExtractionService' in luigi-extractor repository"
"Find all files containing 'Neo4j' in the codebase"
```

### Search Repositories
```
"Search for repositories related to 'knowledge extraction'"
"Find Ruby on Rails repositories I own"
```

### Search Issues/PRs
```
"Search for issues containing 'deployment'"
"Find pull requests related to 'Railway'"
```

### Search Users
```
"Find users with expertise in Rails and Neo4j"
```

## 🚀 Deployment Workflow

### Prepare for Railway Deployment
```
"Create a new branch called 'railway-deployment'"
"Add Railway deployment files to the repository"
"Create a pull request for Railway integration"
"Push all changes to the deployment branch"
"Create a production-ready release"
```

### Post-Deployment
```
"Create an issue to track deployment status"
"Update README with deployment instructions"
"Tag the current commit as v1.0 for production release"
```

## 🔧 Advanced Operations

### Repository Settings
```
"Update repository description for luigi-extractor"
"Change repository visibility to public"
"Add topics/tags to the repository"
```

### Release Management
```
"Create a new release v1.0.0"
"Generate release notes for the latest version"
"Upload release assets"
```

### Webhooks and Actions
```
"List GitHub Actions workflows"
"Check the status of the latest workflow run"
"Trigger a workflow dispatch"
```

## 🛠️ Troubleshooting Commands

### Debug Repository State
```
"Show the current status of luigi-extractor repository"
"List recent commits in the main branch"
"Check if there are any pending pull requests"
```

### Verify Configuration
```
"Test GitHub API connection"
"Verify my GitHub permissions"
"Show my GitHub user information"
```

## 💡 Best Practices

### Commit Messages
- Use descriptive commit messages
- Reference issues when applicable
- Follow conventional commit format

### Branch Naming
- `feature/description` for new features
- `bugfix/description` for bug fixes
- `deployment/platform` for deployment configs
- `hotfix/description` for urgent fixes

### Pull Request Workflow
1. Create feature branch
2. Make changes
3. Push to GitHub
4. Create pull request
5. Request review
6. Merge after approval

### Security
- Never commit sensitive tokens
- Use environment variables for secrets
- Review permissions regularly
- Use fine-grained tokens

## 🔗 Integration Examples

### Railway Deployment
```
"Create a railway.toml configuration file"
"Add environment variables for Railway deployment"
"Create GitHub Actions workflow for automatic deployment to Railway"
"Set up production database connection strings"
```

### CI/CD Pipeline
```
"Create GitHub Actions workflow for testing"
"Add deployment step to Railway after tests pass"
"Set up automatic dependency updates"
"Configure security scanning"
```

---

**Pro Tip:** Start commands with context like "In my luigi-extractor repository, ..." for clarity.

**Remember:** All operations respect your GitHub permissions and repository settings.