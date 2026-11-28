# Proposal: Declarative LDAP Configuration

Status: **Draft for discussion; not implemented or approved for the roadmap.**
The examples below describe a proposed interface, not supported Zammad configuration.

## Problem and scope

Operators can provision Zammad infrastructure reproducibly, but configuring LDAP sources and their role mappings
still involves a separate configuration step. Calling internal Rails models from deployment scripts couples those
scripts to implementation details rather than a supported configuration contract.

[Helm issue #267](https://github.com/zammad/zammad-helm/issues/267) discussed configuration as code.
[Merged PR #272](https://github.com/zammad/zammad-helm/pull/272) added custom volumes and mounts, providing a way to
supply configuration scripts. This proposal addresses the application-level LDAP contract, not those Helm capabilities.
The community has also asked about
[LDAP setup without the UI](https://community.zammad.org/t/how-to-configure-ldap-from-cli-instead-of-web-ui/12745).

The initial scope is LDAP sources, attribute mappings, and directory-group-to-role mappings. It does not include
managing tickets, creating directory users, changing local passwords, or configuring every Zammad object.
A supported CLI or API would be sufficient; configuration interpretation need not live in the Helm chart.

## User stories

- As an operator, I can configure LDAP on a fresh installation without repeating the setup wizard.
- As an administrator, I can review access-filter and role-mapping changes before applying them.
- As an operator, I can reapply configuration without creating duplicate sources or resetting credentials.
- As an administrator, I can keep a local recovery administrator independent of LDAP synchronization.
- As an operator, I can reuse configuration across installations without copying numeric database role IDs.

## Illustrative configuration

The format and field names below are proposals, not a compatibility promise.
All directory names and endpoints are examples.

```yaml
apiVersion: zammad.org/ldap-config/v1alpha1
sources:
  - key: corporate-directory
    name: Corporate directory
    enabled: true
    connection:
      host: ldap.example.org
      port: 636
      tls:
        mode: ldaps
        verify: true
        caFile: /run/secrets/ldap/ca.pem
      bind:
        dn: uid=helpdesk,ou=services,dc=example,dc=org
        passwordFile: /run/secrets/ldap/password
    search:
      baseDN: dc=example,dc=org
      userFilter: (objectClass=inetOrgPerson)
      userIdentifier: uid
      groupFilter: (objectClass=groupOfNames)
      groupIdentifier: dn
    attributes:
      uid: login
      givenName: firstname
      sn: lastname
      mail: email
    roleMappings:
      - groupDN: cn=support-agents,ou=groups,dc=example,dc=org
        roles: [Agent]
        includeNested: false
      - groupDN: cn=support-customers,ou=groups,dc=example,dc=org
        roles: [Customer]
        includeNested: false
    unmatchedUsers: skip
```

Secret files should work with ordinary filesystem permissions, including read-only Kubernetes Secret mounts.
No Kubernetes-specific runtime dependency is required. Bind credentials must not appear in exports, plans, or logs.
Unknown roles, duplicate source keys, invalid filters, and unknown schema fields must be rejected before mutation.

## Proposed operations

The exact CLI syntax or API endpoints remain open for discussion. The interface should distinguish these operations:

1. **Validate:** check schema, references, and local prerequisites without modifying configuration or users.
2. **Check connection:** explicitly test directory access and certificate validation. This is optional and distinct
   from offline validation; no user synchronization occurs as a side effect.
3. **Plan:** show a redacted configuration diff without writing settings, credentials, or synchronization state.
4. **Apply:** transactionally create or update managed sources after validation. Reapplying identical configuration
   is a no-op. Concurrent applies must not create duplicate sources or overwrite intervening changes silently.
5. **Synchronize:** use the existing LDAP synchronization mechanism, with documented scheduling and failure behavior.
   Configuration application and user synchronization must have separate outcomes and observable status.

TLS verification should be enabled by default. Invalid certificates or credentials must not cause a fallback to
unencrypted or unverified connections. A failed check must preserve the previous configuration.

## Ownership, updates, and removal

A stable key identifies each managed source independently of its display name and database ID.
Adopting an existing UI-created source should require an explicit action rather than matching only by name.
Unmanaged sources remain unchanged.

The managed fields must have an explicit ownership policy. For an initial implementation, displaying them as read-only
in the UI would avoid competing writers. Removing a source from the file should report it as unmanaged configuration
drift requiring an explicit removal or ownership-release action, rather than silently deleting it.

Omitted fields on an existing managed source retain their values; resetting a field requires an explicit supported
operation. Required fields must be supplied when creating a source. These semantics must be validated and documented.
Changing a referenced secret file should update the bind credential on apply without exposing its contents.

Role names resolve against the target installation. LDAP memberships remain authoritative during synchronization;
configuration apply must not directly assign roles to individual directory users or bypass synchronization policies.
A plan should flag changes that can affect access, while making clear that an offline plan cannot enumerate every
impacted directory user. A separate preview could use directory access to estimate the effect.

Removing a mapping, narrowing a user filter, disabling a source, and deleting a source are different operations.
Their effects on already-synchronized accounts, sessions, and tokens need explicit documentation and tests.
Directory failures must not be interpreted as a successful empty search that deactivates every user.
Local accounts must remain outside LDAP synchronization, and the last usable administrator must be protected.

## Acceptance criteria

| Scenario | Expected result |
| --- | --- |
| Apply a valid new source | One managed source is created with the requested mappings. |
| Apply the same document again | No duplicate source, unnecessary update, or credential reset. |
| Change a display name or role mapping | The same source is updated; roles resolve by name. |
| Rotate the bind secret | The new credential is used without leaking either value. |
| Unknown role, malformed filter, or missing required secret | Apply fails before changing the stored configuration. |
| Validation or plan | No configuration writes, credential changes, or user synchronization. |
| Explicit connection check fails | Previous configuration is retained; no TLS downgrade occurs. |
| Concurrent applies | Deterministic conflict handling; no duplicate managed keys. |
| Existing unmanaged source | Unchanged unless explicitly adopted. |
| Missing source in a later document | No implicit deletion of the source, users, or tickets. |
| Directory membership revoked | Existing synchronization applies the documented access-revocation policy. |
| Directory temporarily unavailable | No mass deactivation due to a failed lookup. |
| Multiple sources with overlapping users | Existing precedence rules are preserved and documented. |
| Local recovery administrator | Unaffected by directory filters and synchronization. |
| Error, log, plan, or export | No bind passwords, tokens, or local password hashes are exposed. |

These are requirements for a future implementation, not tests claimed to pass in this documentation-only proposal.

## Open design questions

- Should this be exposed through a CLI, a supported API, or both?
- Can existing source-validation services be reused without depending on the setup wizard's intermediate state?
- What explicit adoption, release, reset, and deletion operations best fit the existing LDAP lifecycle?
- Which access-impact checks can be reliable without querying the directory?
- How should administrators unlock file-managed settings during recovery?

This proposal does not establish a roadmap commitment. Product review and agreement on the contract should precede
an implementation PR, following the project's contribution process.
