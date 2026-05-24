# Faithful agent Users panel — matches docs/ui-references/agent-console/
# (UsersPanel in agent-manage.jsx).
class App.AgentUsersFaithful extends App.Controller
  @requiredPermission: 'admin.user'

  elements:
    '.js-search': 'searchInput'

  events:
    'click .js-section': 'onSectionClick'
    'click .js-chip':    'onChipClick'
    'input .js-search':  'onSearchInput'
    'click tbody tr.js-row': 'onRowClick'

  constructor: (params) ->
    super
    @title __('Users'), true
    @navupdate '#manage/users'

    @filter = 'all'
    @query  = ''
    @users  = []

    @fetchUsers()
    @render()

  release: => super

  fetchUsers: =>
    @ajax(
      id:    'agent_users_faithful'
      type:  'GET'
      url:   "#{@apiPath}/users/search"
      data:
        query: '*'
        limit: 200
        expand: true
      processData: true
      success: (data) =>
        # Response is an array of expanded users (id, login, email, firstname,
        # lastname, role_ids, roles[], organization, etc.).
        @users = data or []
        @render()
      error: =>
        # Fallback to local collection if search isn't permitted
        @users = App.User.all().map (u) -> u.attributes()
        @render()
    )

  onSearchInput: (e) =>
    @query = e.target.value
    @rerenderRows()

  onChipClick: (e) =>
    e.preventDefault()
    @filter = $(e.currentTarget).data('chip')
    @render()

  onSectionClick: (e) =>
    e.preventDefault()
    target = $(e.currentTarget).data('section')
    return if !target
    @navigate target

  onRowClick: (e) =>
    id = $(e.currentTarget).data('id')
    return if !id
    @navigate "#user/profile/#{id}"

  kindFor: (u) ->
    roles = (u.roles or u.role_ids?.map((id) -> App.Role.find(id)?.name) or []).filter(Boolean).map((r) -> (r or '').toString())
    return 'admin'    if roles.indexOf('Admin') isnt -1
    return 'agent'    if roles.indexOf('Agent') isnt -1
    return 'customer' if roles.indexOf('Customer') isnt -1
    'other'

  primaryRole: (u) ->
    k = @kindFor(u)
    return 'Admin'    if k is 'admin'
    return 'Agent'    if k is 'agent'
    return 'Customer' if k is 'customer'
    '—'

  initials: (u) ->
    fn = (u.firstname or '').trim()
    ln = (u.lastname  or '').trim()
    if fn or ln
      "#{(fn[0] or '').toUpperCase()}#{(ln[0] or '').toUpperCase()}".trim() or '?'
    else
      ((u.login or u.email or '?')[0] or '?').toUpperCase()

  fullName: (u) ->
    name = "#{u.firstname or ''} #{u.lastname or ''}".trim()
    name or u.login or u.email or '—'

  orgName: (u) ->
    if u.organization
      return u.organization.name or u.organization if typeof u.organization is 'object'
      return u.organization
    if u.organization_id
      App.Organization.find(u.organization_id)?.name or '—'
    else
      '—'

  isActive: (u) ->
    return false if u.active is false
    true

  decorated: ->
    rows = []
    for u in @users
      next =
        id:         u.id
        kind:       @kindFor(u)
        role:       @primaryRole(u)
        name:       @fullName(u)
        email:      u.email or u.login or ''
        org:        @orgName(u)
        initials:   @initials(u)
        isActive:   @isActive(u)
      rows.push next
    rows

  filteredRows: ->
    rows = @decorated()
    if @filter isnt 'all'
      rows = rows.filter (r) => r.kind is @filter
    if @query.trim()
      q = @query.toLowerCase()
      rows = rows.filter (r) ->
        (r.name or '').toLowerCase().indexOf(q) isnt -1 or
        (r.email or '').toLowerCase().indexOf(q) isnt -1
    rows

  counts: ->
    all = @decorated()
    {
      all:      all.length
      admin:    (all.filter (r) -> r.kind is 'admin').length
      agent:    (all.filter (r) -> r.kind is 'agent').length
      customer: (all.filter (r) -> r.kind is 'customer').length
    }

  sections: ->
    items = [
      { key: 'users',         label: 'Users',         href: '#manage/users' }
      { key: 'groups',        label: 'Groups',        href: '#manage/groups' }
      { key: 'roles',         label: 'Roles',         href: '#manage/roles' }
      { key: 'organizations', label: 'Organizations', href: '#manage/organizations' }
      { key: 'macros',        label: 'Macros',        href: '#manage/macros' }
      { key: 'templates',     label: 'Templates',     href: '#manage/templates' }
      { key: 'tags',          label: 'Tags',          href: '#manage/tags' }
      { key: 'slas',          label: 'SLAs',          href: '#manage/slas' }
      { key: 'triggers',      label: 'Triggers',      href: '#manage/trigger' }
    ]
    item.active = (item.key is 'users') for item in items
    items

  render: =>
    rows = @filteredRows()
    @html App.view('agent_users_faithful')(
      sections:  @sections()
      rows:      rows
      counts:    @counts()
      filter:    @filter
      query:     @query
    )

  rerenderRows: => @render()

App.Config.set('AgentUsersFaithful', { controller: 'AgentUsersFaithful', permission: ['admin.user'] }, 'permanentTask')
