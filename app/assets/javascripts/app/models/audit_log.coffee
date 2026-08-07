class App.AuditLog extends App.Model
  @configure 'AuditLog', 'user_id', 'user_fullname', 'action_type', 'auditable_type', 'auditable_id', 'auditable_name', 'value_from', 'value_to', 'source_ip', 'preferences'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/audit_logs'

  @configure_attributes = [
    { name: 'action_type',    display: __('Action'),    tag: 'select', options: { create: __('create object'), update: __('update object'), destroy: __('delete object'), switch_to: __('switch to user'), switch_back_to: __('switch back to user') }, translate: true, null: true },
    { name: 'user_fullname',  display: __('Updated by'), tag: 'input',  type: 'text', limit: 255, null: true },
    { name: 'auditable_type', display: __('Object Type'), tag: 'input',  type: 'text', limit: 255, null: true },
    { name: 'auditable_name', display: __('Object name'), tag: 'input', type: 'text', limit: 255, null: true },
    { name: 'diff',           display: __('Changes'),   tag: 'audit_log_diff', null: true },
    { name: 'source_ip',      display: __('Source IP'), tag: 'input',  type: 'text', limit: 50, null: true },
    { name: 'created_at',     display: __('Created at'), tag: 'datetime', null: true },
  ]
  @configure_overview = [
    'user_fullname',
    'action_type',
    'auditable_type',
    'auditable_name',
    'source_ip',
    'created_at',
  ]

  @description = __('''
The audit log records security-relevant changes in your system: who changed what, and when.

**Configuration changes** in the admin area:

- Groups, roles, and permissions
- Overviews, triggers, schedulers, macros, templates, text modules, and checklist templates
- Channels, postmaster filters, signatures, LDAP sources, and webhooks
- Calendars, SLAs, time accounting, core workflows, object attributes, public links, and report profiles
- System settings and packages
- AI agents and AI text tools
- S/MIME, PGP, and SSL certificates
- Knowledge bases and their languages

**User account changes** (of agents and admins only):

- Password changes
- Activation and deactivation of accounts
- Added or removed roles and group permissions
- Two-factor authentication changes

**Session events**:

- Taking over another user's session via "switch to user" and switching back

An arrow in the "Updated by" column (e.g. "John Doe → Jane Doe") indicates that the action was performed via "switch to user".

Day-to-day work such as ticket updates is not part of the audit log — it is covered by the ticket history instead.
''')

  displayName: ->
    @action_type
