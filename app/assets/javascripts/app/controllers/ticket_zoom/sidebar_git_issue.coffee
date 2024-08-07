class App.SidebarGitIssue extends App.Controller
  provider: '_need_to_be_defined_' # GitLab
  urlPlaceholder: '_need_to_be_defined_' # https://git.example.com/group1/project1/-/issues/1

  constructor: ->
    super
    @issueGids      = []
    @issueData      = []
    @providerIdentifier = @provider.toLowerCase()

  sidebarItem: =>
    return if !@Config.get("#{@providerIdentifier}_integration")

    isAgentTicketZoom   = (@ticket and @ticket.currentView() is 'agent')
    isAgentTicketCreate = (!@ticket and @taskKey and @taskKey.match('TicketCreateScreen-'))

    return if !isAgentTicketZoom and !isAgentTicketCreate

    @item = {
      name: @providerIdentifier
      badgeCallback: @badgeRender
      sidebarHead: @provider
      sidebarCallback: @reloadIssues
      sidebarActions: [
        {
          title:    __('Link issue')
          name:     'link-issue'
          callback: @linkIssue
        },
      ]
    }
    @item

  shown: ->
    return if !@ticket

    @listIssues()

  metaBadge: =>
    counter = ''
    counter = @issueGids.length

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
    return if !@badgeEl
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(@metaBadge()))

  linkIssue: =>
    new App.GitIssueLinkModal(
      head: @provider
      placeholder: @urlPlaceholder
      taskKey: @taskKey
      container: @el.closest('.content')
      callback: (link, ui) =>
        @getIssuesByUrls(
          links: [link]
          success: (result) =>
            if !_.contains(@issueGids, result[0].gid)
              @issueGids.push(result[0].gid)
              @issueData = @issueData.concat(result)

            if @ticket && @ticket.id
              @saveIssues(
                ticket_id: @ticket.id
                gids: @issueGids
                success: =>
                  ui.close()
                  @renderIssues()
                error: (message = __('The issue could not be saved.')) =>
                  ui.showAlert(App.i18n.translatePlain(message))
                  form = ui.el.find('.js-result')
                  @formEnable(form)
              )
            else
              ui.close()
              @renderIssues()
          error: (message = __('Loading failed.')) =>
            ui.showAlert(App.i18n.translatePlain(message))
            form = ui.el.find('.js-result')
            @formEnable(form)
        )
    )

  migrateIssueLinksToGids: (links) =>
    @getIssuesByUrls(
      links: links
      success: (result) =>
        for data from result
          if !_.contains(@issueGids, data.gid)
            @issueGids.push(data.gid)
            @issueData = @issueData.concat(data)

        if @ticket && @ticket.id
          @saveIssues(
            ticket_id: @ticket.id
            gids: @issueGids
            success: =>
              # issue_links of ticket preferences at this point already deleted by the backends issue update logic, delete it here to preserve data consistence
              delete @ticket?.preferences?[@providerIdentifier]?['issue_links']
            error: (message = __('The issue could not be saved.')) =>
              # that's really bad, but don't worry - issue_links data won't be deleted until migration was once successful
          )
      error: (message = __('Loading failed.')) =>
        # can't even migrate (already?) broken links to gids, how dare it
        console.error('Possibly non-accessible git links can\'t be migrated');
    )

  reloadIssues: (el) =>
    if el
      @el = el

    return @renderIssues() if !@ticket

    if @ticket?.preferences?[@providerIdentifier]?.issue_links
      # array assignments required to prevent rendering issues in case the server pushes old ticket issue_links state into the frontend
      @issueData = []
      @issueGids = []
      @migrateIssueLinksToGids(@ticket?.preferences?[@providerIdentifier]?.issue_links)

    ticketGids = @ticket?.preferences?[@providerIdentifier]?.gids || []
    return @renderIssues() if _.isEqual(@issueGids, ticketGids)

    @issueGids = ticketGids
    @listIssues(true)

  renderIssues: =>
    if _.isEmpty(@issueData)
      @showEmpty()
      return

    list = $(App.view('ticket_zoom/sidebar_git_issue')(
      issues: @issueData
    ))
    list.on('click', '.js-delete', (e) =>
      e.preventDefault()
      issueGid = $(e.currentTarget).attr 'data-issue-id'
      @deleteIssue(issueGid)
    )
    @html(list)
    @badgeRenderLocal()

  listIssues: (force = false) =>
    return @renderIssues() if !force && @fetchFullActive && @fetchFullActive > new Date().getTime() - 5000
    @fetchFullActive = new Date().getTime()

    return @renderIssues() if _.isEmpty(@issueGids)

    @getIssuesByGids(
      gids: @issueGids
      success: (result) =>
        @issueGids = result.map((element) -> element.gid)
        @issueData = result
        @renderIssues()
      error: =>
        @showError(App.i18n.translateInline('Loading failed.'))
    )

  getIssuesByUrls: (params) ->
    @ajax(
      id:    "#{@providerIdentifier}-#{@taskKey}"
      type:  'POST'
      url:   "#{@apiPath}/integration/#{@providerIdentifier}"
      data: JSON.stringify(links: params.links)
      success: (data, status, xhr) ->
        if data.response

          # some issues redirect to pull requests like
          # https://github.com/zammad/zammad/issues/1574
          # in this case throw error
          return params.error(__('Loading failed.')) if _.isEmpty(data.response)

          params.success(data.response)
        else
          params.error(data.message)
      error: (xhr, status, error) ->
        return if status is 'abort'

        params.error()
    )

  getIssuesByGids: (params) ->
    @ajax(
      id:    "#{@providerIdentifier}-#{@taskKey}"
      type:  'POST'
      url:   "#{@apiPath}/integration/#{@providerIdentifier}"
      data: JSON.stringify(gids: params.gids)
      success: (data, status, xhr) ->
        if data.response

          # some issues redirect to pull requests like
          # https://github.com/zammad/zammad/issues/1574
          # in this case throw error
          return params.error(__('Loading failed.')) if _.isEmpty(data.response)

          params.success(data.response)
        else
          params.error(data.message)
      error: (xhr, status, error) ->
        return if status is 'abort'

        params.error()
    )

  saveIssues: (params) ->
    App.Ajax.request(
      id:    "#{@providerIdentifier}-update-#{params.ticket_id}"
      type:  'POST'
      url:   "#{@apiPath}/integration/#{@providerIdentifier}_ticket_update"
      data:  JSON.stringify(ticket_id: params.ticket_id, gids: params.gids)
      success: (data, status, xhr) ->
        params.success(data)
      error: (xhr, status, details) ->
        return if status is 'abort'

        params.error()
    )

  deleteIssue: (gid) ->
    @issueGids    = _.filter(@issueGids, (element) -> element isnt gid)
    @issueData = _.filter(@issueData, (element) -> element.gid isnt gid)

    if @ticket && @ticket.id
      @saveIssues(
        ticket_id: @ticket.id
        gids: @issueGids
        success: =>
          @renderIssues()
        error: (message = __('The issue could not be saved.')) =>
          @showError(App.i18n.translateInline(message))
      )
    else
      @renderIssues()

  showEmpty: ->
    @html("<div>#{App.i18n.translateInline('No linked issues')}</div>")
    @badgeRenderLocal()

  showError: (message) =>
    @html App.i18n.translateInline(message)

  reload: =>
    @reloadIssues()

  postParams: (args) =>
    return if !args.ticket
    return if args.ticket.created_at
    return if !@issueGids
    return if _.isEmpty(@issueGids)
    args.ticket.preferences ||= {}
    args.ticket.preferences[@providerIdentifier] ||= {}
    args.ticket.preferences[@providerIdentifier].gids = @issueGids
