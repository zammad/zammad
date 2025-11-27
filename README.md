# Welcome to Zammad

<img width="705" height="503" alt="image" src="https://github.com/user-attachments/assets/c874e72e-6af6-420c-ae8f-4e518a39261a" />

Are you juggling countless customer inquiries across multiple channels?
Struggling to keep your support team on the same page?
Or spending more time managing your helpdesk than delivering exceptional support to your customers?
Zammad is your Swiss Army knife - a web-based, open-source helpdesk and customer support platform
packed with features to streamline customer communication across channels like email, chat, telephone and social media.

## The Software
The Zammad software is and will stay open source. It is licensed under the GNU AGPLv3.
The source code is [available on GitHub](https://github.com/zammad/zammad) and owned by
the [Zammad Foundation](https://zammad-foundation.org/), which is independent of commercial
providers such as Zammad GmbH.

## The Company - Zammad GmbH
The development of Zammad is carried out by the [amazing team of people](https://zammad.com/en/company)
at [Zammad GmbH](https://zammad.com/) in collaboration with the community.
We love to create open source software for you. If you want to ensure the Zammad software
has a bright and sustainable future, consider becoming a Zammad customer!

> Are you tired of complex setup, configuration, backup and update tasks? Let us handle this stuff for you! 🚀
>
> The easiest and often most cost-effective way to operate Zammad is [our cloud service](https://zammad.com/en/pricing).
> Give it a try with a [free trial instance](https://zammad.com/en/getting-started)!

## ⚡ Quick Start - Automated Installation (Ubuntu 24.04)

### One-Command Installation

For a production-ready Zammad deployment with Elasticsearch on Ubuntu 24.04, use our automated installer:

```bash
# Download and execute the FUSED GAMING installation script
wget https://raw.githubusercontent.com/[fork-repo]/zammad/develop/scripts/install-zammad-with-elasticsearch.sh
chmod +x install-zammad-with-elasticsearch.sh
./install-zammad-with-elasticsearch.sh
```

**What this installs:**
- ✅ Ubuntu 24.04 locale configuration
- ✅ Elasticsearch 7.x with ingest-attachment plugin (search indexing)
- ✅ Zammad ticketing system with all dependencies
- ✅ Zammad Web Interface, Worker, and WebSocket services
- ✅ UFW firewall configuration (ports 80, 443, 22, 9200)
- ✅ Automatic service enablement on system boot

**Hardware Requirements:**
- 12GB+ RAM
- 6+ CPU cores
- 100GB+ disk space

### Manual Installation

For more granular control, see the [Installation Documentation](https://docs.zammad.org/en/latest/install/package.html).

### First Steps After Installation

1. **Access the Web Interface**
   ```
   http://your-server-ip
   ```

2. **Complete Initial Setup**
   - Click "Setup new System"
   - Create your admin account
   - Configure organization name
   - Set system URL
   - Configure SMTP for email notifications

3. **Verify Services**
   ```bash
   systemctl status zammad
   systemctl status zammad-web
   systemctl status zammad-worker
   systemctl status zammad-websocket
   ```

4. **Configure Elasticsearch (Optional but Recommended)**
   - Navigate to Admin Panel → System → Elasticsearch
   - Verify connection to elasticsearch:9200
   - Rebuild search index if needed

### Useful Commands

```bash
# Restart all Zammad services
sudo systemctl restart zammad

# View live worker logs
sudo journalctl -u zammad-worker -f

# Check system status
sudo systemctl status zammad-*

# Enable/disable services
sudo systemctl enable zammad-web
sudo systemctl disable zammad-web
```

## Status
- Toolchain: [![CI](https://github.com/zammad/zammad/workflows/CI/badge.svg)](https://github.com/zammad/zammad/actions/workflows/ci.yaml)
  [![docker-release workflow](https://github.com/zammad/zammad/workflows/docker-release/badge.svg)](https://github.com/zammad/zammad/actions/workflows/docker-release.yaml)
  [![documentation status](https://readthedocs.org/projects/zammad/badge/)](https://docs.zammad.org)
- Docker container images: [![Docker images for Zammad](https://img.shields.io/badge/version-stable-blue.svg)](https://hub.docker.com/r/zammad/zammad-docker-compose)
  [![Dockerhub Pulls](https://badgen.net/docker/pulls/zammad/zammad-docker-compose?icon=docker&label=pulls)](https://hub.docker.com/r/zammad/zammad-docker-compose/)
- Helm chart for Kubernetes: [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/zammad)](https://artifacthub.io/packages/helm/zammad/zammad)
  [![Release downloads](https://img.shields.io/github/downloads/zammad/zammad-helm/total.svg)](https://github.com/zammad/zammad-helm/releases)
- Download DEB/RPM: [![binary packages for Zammad stable](https://img.shields.io/badge/Branch-stable-blue.svg)](https://packager.io/gh/zammad/zammad/refs/stable)
  [![binary packages for Zammad develop](https://img.shields.io/badge/Branch-develop-lightgrey.svg)](https://packager.io/gh/zammad/zammad/refs/develop)
- License: [![AGPL license](https://img.shields.io/badge/License-AGPL%203.0-brightgreen.svg)](https://github.com/zammad/zammad/blob/develop/LICENSE)

## Contributing to This Fork

This fork includes community-contributed enhancements and installation automation. We welcome contributions!

### Installation Scripts & Tooling

This fork includes automated installation scripts in the `/scripts` directory:

- **`install-zammad-with-elasticsearch.sh`** - Production-ready Ubuntu 24.04 installer with full error handling and ASCII art branding
- **`install-zammad.sh`** - Lightweight Zammad-only installation (no Elasticsearch)

These scripts are designed to be:
- **Idempotent** - Safe to run multiple times
- **Forgiving** - Non-critical errors won't halt installation
- **Well-documented** - Clear output and progress indicators
- **Production-ready** - Includes firewall, service enablement, and status verification

### Contributing Installation Improvements

If you've improved the installation process for specific environments (Ubuntu versions, cloud providers, container platforms, etc.), please submit a PR with:

1. **Script location**: `/scripts/install-zammad-[platform]-[version].sh`
2. **Documentation**: Update this README with platform-specific instructions
3. **Testing**: Confirm the script works on a clean system
4. **Error handling**: Use forgiving error patterns (`command || echo "warning"`) for non-critical steps
5. **Branding**: Include header comments with author attribution

### Contributing Code

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/my-improvement`)
3. Make your changes with clear commit messages
4. Ensure tests pass
5. Submit a Pull Request to the upstream Zammad repository

Please follow the [official contribution guidelines](https://zammad.org/participate).

### Reporting Issues

- **Zammad bugs**: Report to [upstream Zammad](https://github.com/zammad/zammad/issues)
- **Installation script issues**: Open an issue in this fork with:
  - Your Ubuntu version
  - Full error output
  - Hardware specifications
  - Steps to reproduce

## Further Information
- [Installing & Getting Started](https://docs.zammad.org)
- [Screenshots](https://zammad.org/screenshots)
- [Developer Manual](/doc/developer_manual/index.md)
- [REST API](https://docs.zammad.org/en/latest/api/intro.html)
- For reporting security vulnerabilities, please see [our security policy](SECURITY.md).
- [Contributing](https://zammad.org/participate)

## Fork Attribution

This fork maintains 100% compatibility with upstream Zammad while adding:
- 🚀 Automated installation scripts for modern Linux distributions
- 📖 Enhanced documentation for rapid deployment
- 🛠️ Community-contributed infrastructure tooling

All original Zammad code and architecture is preserved. This fork is designed to be easily merged back upstream or kept as a community resource.

---

Thanks! ❤️ ❤️ ❤️

Your Zammad Team + Community Contributors

---

**Installation scripts authored by: [jlucus](https://github.com/jlucus) @ FUSED GAMING**
