# Contributing to Zammad

Thank you for your interest in contributing to Zammad! This document provides guidelines for contributing to this fork, whether you're improving installation scripts, documentation, or the core platform.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Types of Contributions](#types-of-contributions)
- [Development Workflow](#development-workflow)
- [Installation Scripts](#installation-scripts)
- [Code Quality](#code-quality)
- [Testing](#testing)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Documentation](#documentation)
- [Reporting Issues](#reporting-issues)
- [Community](#community)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please be respectful and constructive in all interactions.

**Be kind. Be professional. Build something great together.**

## Getting Started

### Prerequisites

- **Git** - For version control
- **GitHub account** - To fork and submit PRs
- **Ubuntu 22.04 or 24.04** - For testing installation scripts
- **Basic shell scripting knowledge** - For script contributions
- **Ruby/JavaScript knowledge** - For core Zammad contributions

### Initial Setup

1. **Fork the Repository**
   ```bash
   git clone https://github.com/YOUR-USERNAME/zammad.git
   cd zammad
   ```

2. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/zammad/zammad.git
   git fetch upstream
   ```

3. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Keep Your Fork Updated**
   ```bash
   git fetch upstream
   git rebase upstream/develop
   ```

## Types of Contributions

### 1. Installation & Deployment Scripts

These are high-priority contributions! We're building a library of deployment automation for different platforms.

**Areas we need:**
- ✅ Additional Linux distributions (Rocky, AlmaLinux, Fedora, etc.)
- ✅ Cloud provider automation (AWS, DigitalOcean, Linode, Hetzner, etc.)
- ✅ Container orchestration (Docker, Kubernetes, Podman)
- ✅ Ansible playbooks & Terraform configurations
- ✅ CI/CD pipeline integrations
- ✅ Backup & restore automation

### 2. Documentation Improvements

- Installation guides for specific environments
- Troubleshooting guides
- Configuration examples
- Performance tuning documentation
- Security hardening guides

### 3. Core Zammad Features

For core platform contributions, see the [official Zammad contributing guide](https://zammad.org/participate).

### 4. Bug Fixes & Performance

- Issue fixes with regression tests
- Performance optimizations
- Security patches
- Dependency updates

## Development Workflow

### Branch Naming Convention

```
feature/description          # New features
bugfix/issue-number         # Bug fixes (reference GitHub issue)
docs/section-name           # Documentation
scripts/platform-version    # Installation scripts
perf/optimization-name      # Performance improvements
```

**Examples:**
```
feature/elasticsearch-optimization
bugfix/#1234-email-routing
docs/aws-deployment-guide
scripts/install-zammad-rocky-9
perf/ticket-search-query
```

### Before You Start

1. **Check for existing issues** - Search [GitHub Issues](https://github.com/zammad/zammad/issues)
2. **Discussion for major changes** - Open an issue to discuss before implementation
3. **Keep scope focused** - One feature/fix per branch
4. **Sync with upstream** - Ensure you're up to date with the main branch

## Installation Scripts

Installation scripts are critical infrastructure for the project. Here's what we expect:

### Script Requirements

#### 1. **File Organization**
```
scripts/
├── install-zammad-ubuntu-24.04.sh
├── install-zammad-debian-12.sh
├── install-zammad-rocky-9.sh
├── install-zammad-with-elasticsearch.sh
└── lib/
    ├── common-functions.sh
    ├── ascii-art.sh
    └── error-handling.sh
```

#### 2. **Header Documentation**
```bash
#!/bin/bash
#
# Zammad Installation Script for [Platform Version]
# Authored by: Your Name (GitHub handle)
# Maintained by: FUSED GAMING Infrastructure Team
#
# Description: Brief description of what this installs
# Tested on: [OS versions tested]
# Requirements: [Hardware/software requirements]
# Usage: ./install-zammad-[platform]-[version].sh
#
# For issues or improvements, open a GitHub issue with:
# - Your system details
# - Full error output
# - Steps to reproduce
#
```

#### 3. **Error Handling**
All scripts MUST use forgiving error handling:

```bash
#!/bin/bash
set -e  # Exit on critical errors

# Non-critical operations should be forgiving
install_optional_plugin() {
  if sudo /path/to/plugin list 2>/dev/null | grep -q my-plugin; then
    echo "✓ Plugin already installed"
  else
    sudo /path/to/plugin install -b my-plugin 2>&1 || {
      echo "⚠️  Plugin installation failed, but continuing..."
    }
  fi
}

# Critical operations should fail loudly
install_core_system() {
  if ! sudo apt-get install -y zammad; then
    echo "❌ CRITICAL: Zammad installation failed"
    exit 1
  fi
}
```

#### 4. **User Feedback**
Scripts must provide clear feedback at every step:

```bash
show_step() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║ $1"
  echo "╚═══════════════════════════════════════════════════════════╝"
}

show_progress() {
  echo "   ✓ $1"
}

show_warning() {
  echo "   ⚠️  $1"
}

show_error() {
  echo "   ❌ $1"
  exit 1
}

# Usage
show_step "Installing Zammad"
show_progress "Zammad installed successfully"
show_warning "Elasticsearch connection pending"
show_error "Critical service failed to start"
```

#### 5. **ASCII Art Branding**
All scripts should include header branding:

```bash
show_banner() {
  cat << 'BANNER'
    
    ███████╗ █████╗ ███╗   ███╗███╗   ███╗ █████╗ ██████╗ ██████╗ 
    ╚════██║██╔══██╗████╗ ████║████╗ ████║██╔══██╗██╔══██╗██╔══██╗
        ██╔╝███████║██╔████╔██║██╔████╔██║███████║██║  ██║██║  ██║
        ██║ ██╔══██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║  ██║██║  ██║
        ██║ ██║  ██║██║ ╚═╝ ██║██║ ╚═╝ ██║██║  ██║██████╔╝██████╔╝
        ╚═╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝ 
                                                                    
    ╔═══════════════════════════════════════════════════════════╗
    ║          ZAMMAD ENTERPRISE TICKETING SYSTEM              ║
    ║             Authored by: [Your Name]                     ║
    ╚═══════════════════════════════════════════════════════════╝

BANNER
}
```

#### 6. **Installation Summary**
End with a clear summary box:

```bash
show_summary() {
  cat << 'SUMMARY'
╔═══════════════════════════════════════════════════════════╗
║               INSTALLATION COMPLETE ✅                    ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  🌐 Access Zammad: http://your-server-ip                ║
║                                                           ║
║  📝 Next Steps:                                           ║
║     1. Complete initial setup in web interface           ║
║     2. Configure SMTP for notifications                  ║
║     3. Import your existing tickets (if any)             ║
║                                                           ║
║  🆘 Service Management:                                   ║
║     systemctl restart zammad    (restart all services)   ║
║     systemctl status zammad-*   (check status)           ║
║                                                           ║
║  📚 Documentation: https://docs.zammad.org               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
SUMMARY
}
```

### Script Testing Checklist

Before submitting a script, verify:

- [ ] **Clean Install Test** - Runs on a fresh VM/container
- [ ] **Idempotency** - Safe to run multiple times
- [ ] **Error Recovery** - Non-critical errors don't break installation
- [ ] **Service Verification** - All services start and are enabled
- [ ] **Firewall Rules** - Correct ports are open
- [ ] **Documentation** - Instructions in PR description
- [ ] **Platform Specific** - Works on declared OS versions
- [ ] **Cleanup** - No temporary files left behind
- [ ] **Performance** - Installation completes in reasonable time
- [ ] **Logging** - User can see what's happening

### Script Submission Template

When submitting a script PR, use this template:

```markdown
## Installation Script: [Platform] [Version]

### What This Script Installs
- [ ] Zammad core
- [ ] Elasticsearch (if applicable)
- [ ] Database (PostgreSQL/MySQL)
- [ ] Web server (Nginx)
- [ ] Firewall configuration
- [ ] Service automation

### Tested On
- OS: [e.g., Ubuntu 24.04 LTS]
- Instance types: [e.g., t3.large on AWS]
- Network: [e.g., public IP, behind load balancer]

### Testing Results
```
$ ./install-zammad-ubuntu-24.04.sh
[Full output showing successful installation]
$ systemctl status zammad
● zammad.service - Loaded: loaded
  Active: active (running) since...
```

### Known Limitations
- [ ] None (or list any)

### Installation Time
- Typical: ~15 minutes
- Range: 10-20 minutes (depending on system specs)

### Success Criteria Met
- [ ] Services start automatically
- [ ] Web interface accessible at http://ip
- [ ] Health checks pass
- [ ] Script handles errors gracefully
```

## Code Quality

### Bash Script Standards

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Use consistent indentation (2 or 4 spaces)
if condition; then
  echo "Indented properly"
fi

# Quote variables
echo "Using: $variable"
echo "Safe: ${array[@]}"

# Use functions for reusability
my_function() {
  local local_var="local scope"
  return 0
}

# Use meaningful variable names
install_elasticsearch() {
  # Good
  local elasticsearch_version="7.17"
  
  # Avoid
  local es_v="7.17"
}

# Comment complex logic
# Calculate required disk space based on ticket volume
required_space=$((ticket_count * 2048))
```

### Ruby/JavaScript Standards

Follow the existing code style in the repository:

- Use linters: `rubocop` for Ruby, `eslint` for JavaScript
- Format code: `prettier` for JavaScript
- Test your changes: Run existing test suite
- Add tests for new features

Run before committing:
```bash
# Ruby
bundle exec rubocop lib/

# JavaScript
npm run lint
npm test
```

## Testing

### Installation Script Testing

1. **Local Testing**
   ```bash
   # Create a clean VM or use Docker
   vagrant up
   vagrant ssh
   ./install-zammad-ubuntu-24.04.sh
   ```

2. **Verify Installation**
   ```bash
   systemctl status zammad
   curl http://localhost/api/version
   ```

3. **Test Idempotency**
   ```bash
   # Run script twice
   ./install-zammad-ubuntu-24.04.sh
   # Run again - should report components already installed
   ./install-zammad-ubuntu-24.04.sh
   ```

### Core Feature Testing

1. **Unit Tests**
   ```bash
   cd zammad
   bundle exec rspec spec/models/
   ```

2. **Integration Tests**
   ```bash
   bundle exec rspec spec/integration/
   ```

3. **Test Coverage**
   ```bash
   COVERAGE=true bundle exec rspec
   ```

## Commit Messages

Write clear, descriptive commit messages:

```
# Good: Follows conventional commits
feat(scripts): add Ubuntu 24.04 installation automation
fix(elasticsearch): handle plugin installation idempotency
docs: update installation guide for AWS deployment
perf: optimize ticket search query performance

# Avoid: Vague messages
git commit -m "fixes"
git commit -m "update stuff"
git commit -m "wip"
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Formatting
- `refactor` - Code reorganization
- `perf` - Performance improvement
- `test` - Testing
- `chore` - Build/dependencies

**Example:**
```
feat(scripts): add Rocky Linux 9 installation script

Add comprehensive Zammad installation script for Rocky Linux 9,
including Elasticsearch integration and firewall configuration.

Tested on: Rocky Linux 9.2
Installation time: ~12 minutes
Fixes: #1234

Signed-off-by: Your Name <your.email@example.com>
```

## Pull Request Process

### Before Submitting

1. **Update your branch**
   ```bash
   git fetch upstream
   git rebase upstream/develop
   ```

2. **Run tests**
   ```bash
   # For scripts
   ./install-zammad-*.sh  # On clean system
   
   # For code
   bundle exec rspec
   npm test
   ```

3. **Verify code quality**
   ```bash
   rubocop lib/
   eslint app/
   ```

4. **Update documentation**
   - Update README if needed
   - Add comments to complex code
   - Update CHANGELOG

### PR Description Template

```markdown
## Description
Brief description of changes and why they're needed.

## Type of Change
- [ ] Installation script
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Performance improvement

## Installation Scripts (if applicable)
- Tested on: [OS and version]
- Hardware used: [CPU, RAM, disk]
- Installation time: [minutes]
- Idempotency: [Yes/No]

## How to Test
```bash
# Steps to verify the changes work
./install-zammad-ubuntu-24.04.sh
systemctl status zammad
```

## Checklist
- [ ] Tested on clean system
- [ ] Documentation updated
- [ ] No breaking changes
- [ ] Commit messages are clear
- [ ] Code follows style guidelines
- [ ] All tests pass

## Related Issues
Fixes #1234
References #5678

## Screenshots (if applicable)
[Add installation summary or web interface screenshots]
```

### Review Process

1. **Automated Checks** - CI pipeline runs tests
2. **Code Review** - Maintainers review for quality and compatibility
3. **Testing** - Scripts are tested on target platforms
4. **Approval** - Approved by at least one maintainer
5. **Merge** - Your contribution is merged!

### Feedback & Changes

- Respond to feedback promptly
- Make requested changes in new commits
- Re-request review after updates
- Ask for clarification if needed

## Documentation

### Writing Good Documentation

1. **Be Clear**
   ```
   Good: "To enable Elasticsearch, set ELASTICSEARCH_ENABLED=true"
   Bad: "Set ES var"
   ```

2. **Include Examples**
   ```
   Good: Show command and expected output
   Bad: Just describe what it does
   ```

3. **Document Assumptions**
   ```
   "This guide assumes you have root/sudo access"
   "Tested on Ubuntu 22.04 and 24.04"
   ```

4. **Add Table of Contents**
   ```markdown
   ## Table of Contents
   - [Installation](#installation)
   - [Configuration](#configuration)
   - [Troubleshooting](#troubleshooting)
   ```

### Documentation Structure

```
docs/
├── installation/
│   ├── ubuntu-24.04.md
│   ├── debian-12.md
│   ├── rocky-9.md
│   └── cloud-providers/
│       ├── aws.md
│       ├── digitalocean.md
│       └── linode.md
├── configuration/
│   ├── smtp.md
│   ├── elasticsearch.md
│   └── ssl.md
├── troubleshooting/
│   ├── service-issues.md
│   ├── database-problems.md
│   └── elasticsearch-problems.md
└── administration/
    ├── backup-restore.md
    ├── monitoring.md
    └── performance-tuning.md
```

## Reporting Issues

### Security Issues

**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, see [SECURITY.md](SECURITY.md) for responsible disclosure procedures.

### Bug Reports

Include:
```markdown
## Description
Clear description of the bug.

## Steps to Reproduce
1. Do this
2. Then this
3. Problem occurs

## Expected Behavior
What should happen instead?

## System Information
- OS: Ubuntu 24.04 LTS
- Zammad Version: 6.5.0
- Installation Method: install-zammad-with-elasticsearch.sh
- Hardware: t3.large, 8GB RAM

## Error Output
```
Full error message and stack trace
```

## Logs
Relevant log excerpts (systemctl logs, journalctl output)
```

### Feature Requests

```markdown
## Description
What problem does this solve?

## Use Case
When would you use this?

## Implementation Ideas
How might this work?

## Related Issues
Links to similar requests or discussions
```

## Community

### Getting Help

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Questions and general discussion
- **Zammad Forum** - Community support at https://zammad-community.org/
- **Chat** - Join community chat (if available)

### Recognition

Contributors are recognized in:
- `CONTRIBUTORS.md` - Lifetime list of all contributors
- Release notes - For each contribution
- GitHub - Automatic contributor badge

## Resources

- [Zammad Official Site](https://zammad.com/)
- [Zammad Documentation](https://docs.zammad.org/)
- [Zammad API](https://docs.zammad.org/en/latest/api/intro.html)
- [Official Contributing Guide](https://zammad.org/participate)
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

## Thank You! 🙏

Your contributions make Zammad better for everyone. We truly appreciate your time and effort!

If you have questions, don't hesitate to ask. We're here to help you succeed.

**Happy coding!**

— The Zammad Team & Community
