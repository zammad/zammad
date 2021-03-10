class App.SidebarGitIssue extends App.Controller
  provider: '_need_to_be_defined_' # GitLab
  urlPlaceholder: '_need_to_be_defined_' # https://git.example.com/group1/project1/-/issues/1

  constructor: ->
    super
    @issueLinks = []
    @providerIdentifier = @provider.toLowerCase()

  sidebarItem: =>
    return if !@Config.get("#{@providerIdentifier}_integration")
    @item = {
      name: @providerIdentifier
      badgeCallback: @badgeRender
      sidebarHead: @provider
      sidebarCallback: @showObjects
      sidebarActions: [
        {
          title:    'Link issue'
          name:     'link-issue'
          callback: @linkIssue
        },
      ]
    }
    @item

  shown: ->
    return if !@ticket
    return if !@ticket.id
    @showIssues()

  metaBadge: =>
    counter = ''
    counter = @issueLinks.length

    {
      name: 'customer'
      icon: "#{@providerIdentifier}-logo"
      counterPossible: true
      counter: counter
    }

  badgeRender: (el) =>
    @badgeEl = el
    @badgeRenderLocal()

  badgeRenderLocal: =>
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(@metaBadge()))

  linkIssue: =>
    new App.GitIssueLinkModal(
      head: @provider
      placeholder: @urlPlaceholder
      taskKey: @taskKey
      container: @el.closest('.content')
      callback: (link, ui) =>
        if @ticket && @ticket.id
          @saveTicketIssues = true
        ui.close()
        @showIssues([link])
    )

  showObjects: (el) =>
    @el = el

    # show placeholder
    if @ticket && @ticket.preferences && @ticket.preferences[@providerIdentifier] && @ticket.preferences[@providerIdentifier].issue_links
      @issueLinks = @ticket.preferences[@providerIdentifier].issue_links
    queryParams = @queryParam()

    # TODO: what is 'gitlab_issue_links'
    if queryParams && queryParams.gitlab_issue_links
      @issueLinks.push queryParams.gitlab_issue_links
    @showIssues()

  showIssues: (issueLinks) =>
    if issueLinks
      @issueLinks = _.uniq(@issueLinks.concat(issueLinks))

    # show placeholder
    if _.isEmpty(@issueLinks)
      @html("<div>#{App.i18n.translateInline('No linked issues')}</div>")
      return

    # AJAX call to show items
    @ajax(
      id:    "#{@providerIdentifier}-#{@taskKey}"
      type:  'POST'
      url:   "#{@apiPath}/integration/#{@providerIdentifier}"
      data: JSON.stringify(links: @issueLinks)
      success: (data, status, xhr) =>
        if data.response
          @showList(data.response)
          if @saveTicketIssues
            @saveTicketIssues = false
            @issueLinks = data.response.map((issue) -> issue.url)
            @updateTicket(@ticket.id, @issueLinks)
          return
        @showError('Unable to load data...')

      error: (xhr, status, error) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @showError('Unable to load data...')
    )

  showList: (issues) =>
    list = $(App.view('ticket_zoom/sidebar_git_issue')(
      issues: issues
    ))
    list.delegate('.js-delete', 'click', (e) =>
      e.preventDefault()
      issueLink = $(e.currentTarget).attr 'data-issue-id'
      @delete(issueLink)
    )
    @html(list)
    @badgeRenderLocal()

  showError: (message) =>
    @html App.i18n.translateInline(message)

  reload: =>
    @showIssues()

  delete: (issueLink) =>
    localLinks = []
    for localLink in @issueLinks
      if issueLink.toString() isnt localLink.toString()
        localLinks.push localLink
    @issueLinks = localLinks
    if @ticket && @ticket.id
      @updateTicket(@ticket.id, @issueLinks)
    @showIssues()

  postParams: (args) =>
    return if !args.ticket
    return if args.ticket.created_at
    return if !@issueLinks
    return if _.isEmpty(@issueLinks)
    args.ticket.preferences ||= {}
    args.ticket.preferences[@providerIdentifier] ||= {}
    args.ticket.preferences[@providerIdentifier].issue_links = @issueLinks

  updateTicket: (ticket_id, issueLinks) =>
    App.Ajax.request(
      id:    "#{@providerIdentifier}-update-#{ticket_id}"
      type:  'POST'
      url:   "#{@apiPath}/integration/#{@providerIdentifier}_ticket_update"
      data:  JSON.stringify(ticket_id: ticket_id, issue_links: issueLinks)
      success: (data, status, xhr) =>
        @badgeRenderLocal()
      error: (xhr, status, details) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @log 'errors', details
        @notify(
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to update object!')
          timeout: 6000
        )
    )
