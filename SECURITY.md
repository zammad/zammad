# Security Policy

## Supported Versions

Security fixes are provided for the [current stable version of Zammad](https://zammad.com/releases) only.
Any older version is not supported and needs to be updated first before reporting security issues.

## Reporting a Vulnerability

If you've found a security vulnerability in Zammad,
please report the vulnerability exclusively via email
to [security@zammad.com](mailto:security@zammad.com).

To send us a secure message, please use [our public key](SECURITY.asc).

We will get back to you as soon as possible and inform
you about the next steps. Accepted vulnerabilities will
be disclosed via patch level release with accompanying
security advisory.

### Reporting Process Overview

- Potential security issues can be reported via [security@zammad.com](mailto:security@zammad.com).
- We evaluate them and provide timely feedback to the reporter.
- There may be security releases created if needed, e.g. [Zammad 6.3.1](https://zammad.com/en/releases/6-3-1).
- We publish security advisories for every acknowledged issue, like [ZAA-2024-04](https://zammad.com/en/advisories/zaa-2024-04).
- After their publication, we request CVE identifiers to be assigned to the advisories.

### Rewards

Every first reporter of a vulnerability may be credited
in the related security advisory.

Zammad does not offer financial compensation through a
security bounty program.

## Security Measures in Development Workflow

Most of our relevant GitLab related configuration related to
Ruby security analysis can be seen in [.gitlab/ci/lint.yml](.gitlab/ci/lint.yml#L49).
With this, you can also locally reproduce the results.

### Dependency Management

We use renovate bot to keep our Ruby and JS dependencies up-to-date by automatic merge requests in our internal GitLab.
This config is not visible in our source code, but you can see frequent commits from it in our history, like
[this one](https://github.com/zammad/zammad/commit/a61b205e4ba41fca1ec7c85323ec6045fc3672e5).

### Dependency Security Analysis

As you can see in the GitLab job linked above, we use
[bundle-audit](https://github.com/rubysec/bundler-audit) to scan for
known security issues in Ruby gems.

### Static Ruby Code Analysis

We use [brakeman](https://brakemanscanner.org/) to scan for
insecure Ruby code constructs, along with an [ignore file](config/brakeman.ignore)
that lists known exceptions.

### Static JS Code Analysis

We use the [SonarJS](https://github.com/SonarSource/SonarJS) plugin for
ESLint for this.
