

# GitHub Workflows Documentation

## Overview

This directory contains GitHub Actions workflows for automated CI/CD, testing, and documentation management.

---

## 📋 Workflows

### 1. **ci-enhanced.yaml** - Enhanced CI Pipeline

**Purpose**: Comprehensive continuous integration with detailed failure diagnostics and PR feedback.

**Triggers**:
- Pull requests
- Weekly schedule (Fridays at 6:00 UTC)

**Features**:
- ✅ **Step-by-step status tracking** - Each step is tracked individually
- ✅ **Automatic PR comments** - Posts detailed results to PR
- ✅ **Failure diagnostics** - Captures logs and provides debugging tips
- ✅ **Cache reporting** - Shows cache hits/misses
- ✅ **Documentation generation** - Auto-generates docs from commits
- ✅ **Artifact uploads** - Saves logs for debugging

**Steps**:
1. **Checkout** - Fetch code with full history
2. **Setup** - Install pnpm, Node.js 22, cache dependencies
3. **Pre-Setup** - Bundle install, pnpm install, database init
4. **Linting** - Rubocop, ESLint, Stylelint, Brakeman security scan
5. **Markdown Linting** - Check all .md files
6. **Testing** - RSpec, Minitest, frontend tests
7. **Reporting** - Generate summary, comment on PR, upload artifacts

**PR Comment Format**:
```markdown
## 🔍 CI Pipeline Results

### Step-by-Step Results

| Step | Status | Details |
|------|--------|----------|
| Code Checkout | ✅ | Passed |
| Pre-Setup | ✅ | Passed |
| Linting | ❌ | Failed |
...

### Overall Status
❌ Some checks failed. Please review the errors above.
```

**Failure Diagnostics**:
- Captures last 50-200 lines of error logs
- Provides common causes and fixes
- Links to relevant debugging commands

---

### 2. **auto-update-docs.yaml** - Automatic Documentation Updates

**Purpose**: Automatically updates documentation when commits are merged to main branches.

**Triggers**:
- Push to `develop`, `main`, or `master` branches

**Features**:
- ✅ **Auto-update CHANGELOG** - Categorizes commits and updates changelog
- ✅ **Migration tracking** - Detects and documents database migrations
- ✅ **Issue creation** - Creates GitHub issues for migrations
- ✅ **Release notes** - Drafts release notes when needed
- ✅ **README updates** - Updates "Last updated" timestamps

**Commit Types Recognized**:
- `feat:` / `feature:` → Features section
- `fix:` / `bugfix:` → Bug Fixes section
- `docs:` / `doc:` → Documentation section
- `refactor:` → Refactoring section
- `test:` / `tests:` → Tests section
- `chore:` → Skipped (not added to changelog)

**CHANGELOG Format**:
```markdown
### 2025-11-30

#### Features
- Feature: Add new user dashboard (`abc1234`)

#### Bug Fixes
- Fix: Resolve login issue (`def5678`)
```

**Migration Detection**:
- Scans for files in `db/migrate/`
- Creates `doc/MIGRATIONS.md` log
- Creates GitHub issue with migration details
- Labels: `database`, `migration`, `deployment`

---

### 3. **ci.yaml** - Standard CI Pipeline (Legacy)

**Purpose**: Original CI pipeline without enhanced reporting.

**Status**: ⚠️  **Deprecated** - Use `ci-enhanced.yaml` instead

This workflow is kept for backward compatibility but will be removed in a future release.

---

### 4. **docker-ci.yaml** - Docker Build Testing

**Purpose**: Validates Docker image builds and docker-compose setup.

**Triggers**:
- Pull requests

**Steps**:
1. Build Docker image
2. Checkout docker-compose files
3. Run docker-compose tests
4. Verify correct image is used

---

### 5. **docker-release.yaml** - Docker Image Publishing

**Purpose**: Publishes Docker images to registry on releases.

**Triggers**:
- Release tags
- Manual workflow dispatch

---

### 6. **packager.io.yaml** - Package Distribution

**Purpose**: Builds and publishes DEB/RPM packages.

**Triggers**:
- Release tags
- Schedule

---

## 🛠️ Supporting Scripts

### `ci/pre.sh`
**Purpose**: Install dependencies and initialize database

**Actions**:
- Configure bundler for deployment
- Run `bundle install`
- Run `pnpm install`
- Configure environment
- Initialize database

### `ci/lint.sh`
**Purpose**: Run all linting checks

**Checks**:
- `.po` file syntax
- Translation catalog consistency
- Brakeman security scan
- Rails zeitwerk autoloader
- GraphQL API consistency
- Rubocop (Ruby style)
- Coffeelint (CoffeeScript)
- TypeScript type checking
- ESLint (JavaScript)
- Stylelint (CSS)

### `ci/test.sh`
**Purpose**: Run all test suites

**Tests**:
- Asset compilation
- Frontend tests (`pnpm test`)
- RSpec (excluding system tests)
- Minitest unit tests

### `ci/generate-summary.sh` ✨ NEW
**Purpose**: Generate comprehensive CI summary report

**Generates**:
- Step-by-step execution results
- Success/failure counts
- Log file inventory
- Debugging recommendations
- Execution timeline

**Output**: `ci-summary.md`

### `ci/generate-docs.sh` ✨ NEW
**Purpose**: Generate documentation from commit messages

**Analyzes**:
- Commit types and counts
- File changes by type
- Migration detection
- Breaking change detection

**Generates**:
- Commit categorization
- Suggested CHANGELOG entries
- File change statistics
- Migration warnings

**Output**: `PR_DOCUMENTATION.md`

---

## 📊 CI Status Tracking

The enhanced CI workflow uses `ci-status.env` to track step results:

```bash
checkout=success
pnpm=success
pre_setup=success
lint=failed
test=success
```

**Status Values**:
- `success` - Step passed
- `failed` - Step failed
- `hit` - Cache hit
- `miss` - Cache miss

---

## 🎯 Using the Enhanced Workflows

### For Pull Requests

1. **Create your PR** - The enhanced CI workflow will run automatically

2. **Check PR comments** - A bot comment will appear with:
   - Step-by-step results table
   - Overall status
   - Error logs (if failures)

3. **Review GitHub Actions** - Click "Details" for full logs

4. **Download artifacts** - If needed, download `ci-logs` artifact for debugging

### For Merges to Main Branches

1. **Commit with conventional format**:
   ```bash
   git commit -m "feat: Add user profile page"
   ```

2. **Merge to develop/main** - Auto-update workflow runs

3. **Check for issues** - If migrations detected, an issue will be created

4. **Review documentation** - CHANGELOG.md will be auto-updated

### Commit Message Format

Use conventional commits for best results:

```
<type>: <description>

<optional body>

<optional footer>
```

**Types**:
- `feat` / `feature` - New feature
- `fix` / `bugfix` - Bug fix
- `docs` / `doc` - Documentation
- `test` / `tests` - Tests
- `refactor` - Code refactoring
- `perf` / `performance` - Performance improvement
- `style` - Code style
- `chore` - Maintenance
- `ci` - CI/CD changes
- `build` - Build system changes

**Examples**:
```bash
# Feature
git commit -m "feat: Add Telegram template system"

# Bug fix
git commit -m "fix: Resolve authentication timeout issue"

# Documentation
git commit -m "docs: Update API documentation for v2"

# Breaking change
git commit -m "feat!: Redesign user API

BREAKING CHANGE: The /api/users endpoint now requires authentication."
```

---

## 🐛 Debugging Failed CI Runs

### Step 1: Check PR Comment

The bot comment shows which step failed. Common failures:

**Pre-Setup Failure**:
```bash
# Fix locally
bundle install
pnpm install
rails db:migrate RAILS_ENV=test
```

**Lint Failure**:
```bash
# Run locally
bundle exec rubocop --autocorrect
pnpm lint:js:fix
pnpm lint:css:fix
```

**Test Failure**:
```bash
# Run locally
bundle exec rspec
pnpm test
```

**Markdown Lint Failure**:
```bash
# Run locally
pnpm lint:md:fix
```

### Step 2: Review Logs

Click "Details" on the failed check to see:
- Full command output
- Error messages
- Stack traces

### Step 3: Download Artifacts

If logs are truncated, download the `ci-logs` artifact:
1. Go to GitHub Actions run
2. Scroll to bottom
3. Download `ci-logs.zip`
4. Extract and review `.log` files

### Step 4: Reproduce Locally

```bash
# Clone and setup
git clone <repo>
cd <repo>
bundle install
pnpm install

# Run the same checks
.github/workflows/ci/pre.sh
.github/workflows/ci/lint.sh
.github/workflows/ci/test.sh
```

---

## ⚙️ Configuration

### Required Secrets

- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

### Optional Secrets

- `DOCKER_USERNAME` - For docker-release workflow
- `DOCKER_PASSWORD` - For docker-release workflow

### Permissions

The enhanced workflows require:
```yaml
permissions:
  contents: write        # Update documentation
  pull-requests: write   # Comment on PRs
  issues: write          # Create migration issues
  checks: write          # Update check status
```

---

## 📈 Workflow Metrics

### CI Pipeline Performance

**Target Times**:
- Checkout & Setup: < 2 minutes
- Pre-Setup: < 5 minutes (< 1 minute with cache hit)
- Linting: < 3 minutes
- Testing: < 10 minutes
- Total: < 20 minutes

**Cache Hit Rates**:
- Bundler: ~80% hit rate
- ESLint: ~90% hit rate
- Node modules: ~85% hit rate

### Auto-Documentation Performance

**Execution Time**: < 1 minute
**Frequency**: Every merge to main branches
**Average Updates**: 1-2 files per commit

---

## 🔄 Migration Guide

### From Standard CI to Enhanced CI

1. **Update workflow file reference** in `.github/workflows/`:
   ```yaml
   # Before
   uses: ./.github/workflows/ci.yaml

   # After
   uses: ./.github/workflows/ci-enhanced.yaml
   ```

2. **Add permissions** to your workflow:
   ```yaml
   permissions:
     contents: write
     pull-requests: write
     checks: write
   ```

3. **Enable auto-documentation** (optional):
   - Add the `auto-update-docs.yaml` workflow
   - Configure branch protection rules

4. **Test on a PR** - Create a test PR to verify the enhanced workflow

---

## 🚀 Future Enhancements

Planned improvements:
- [ ] Performance profiling integration
- [ ] Security vulnerability scanning (Snyk, Dependabot)
- [ ] Code coverage reporting
- [ ] Visual regression testing
- [ ] Accessibility testing
- [ ] Load testing for API endpoints
- [ ] Automatic version bumping
- [ ] Slack/Discord notifications

---

## 📞 Support

For issues with workflows:
1. Check the [GitHub Actions documentation](https://docs.github.com/en/actions)
2. Review workflow logs in GitHub Actions UI
3. Open an issue with:
   - Workflow name
   - Run ID
   - Error message
   - Steps to reproduce

---

## 📄 License

These workflows are part of the Zammad project and are licensed under AGPL 3.0.

---

**Last Updated**: 2025-11-30
**Maintained By**: Community Contributors
