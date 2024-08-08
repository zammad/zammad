class App.SidebarGitIssue extends App.Controller
  provider: '_need_to_be_defined_' # GitLab
  urlPlaceholder: '_need_to_be_defined_' # https://git.example.com/group1/project1/-/issues/1

  constructor: ->
    super
    @issueLinks     = []
    @issueGids      = []
    @issueData      = []
    @error          = ''
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
    counter = @issueGids.length + @issueLinks.length

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
                issue_links: @issueLinks
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

  reloadIssues: (el) =>
    if el
      @el = el

    @error = ''

    return @renderIssues() if !@ticket

    ticketGids = @ticket?.preferences?[@providerIdentifier]?.gids || []
    ticketLinks = @ticket?.preferences?[@providerIdentifier]?.issue_links || []
    return @renderIssues() if _.isEqual(@issueGids, ticketGids) && _.isEqual(@issueLinks, ticketLinks)

    @issueGids = ticketGids
    @issueLinks = ticketLinks
    @listIssues(true)

  renderIssues: =>
    if _.isEmpty(@issueData)
      @showEmpty()
      return

    list = $(App.view('ticket_zoom/sidebar_git_issue')(
      error: @error
      issues: @issueData
    ))
    list.on('click', '.js-delete', (e) =>
      e.preventDefault()
      issueGid = $(e.currentTarget).attr 'data-issue-id'
      if issueGid
        @deleteIssueByGid(issueGid)
      else
        issueUrl = $(e.currentTarget).attr 'data-issue-url'
        @deleteIssueByUrl(issueUrl)
    )
    @html(list)
    @badgeRenderLocal()

  listIssues: (force = false) =>
    return @renderIssues() if !force && @fetchFullActive && @fetchFullActive > new Date().getTime() - 5000
    @fetchFullActive = new Date().getTime()

    return @renderIssues() if _.isEmpty(@issueGids) && _.isEmpty(@issueLinks)

    @getIssuesByGids(
      gids: @issueGids
      success: (result) =>
        @issueGids = result.map((element) -> element.gid)
        @issueData = result

        @getIssuesByUrlsForListing()
      error: (message = __('Loading issues failed.')) =>
        @showError(message)

        @issueGids = []
        @issueData = []
        @getIssuesByUrlsForListing()
    )

  getIssuesByUrlsForListing: () ->
    if !_.isEmpty(@issueLinks)
      @getIssuesByUrls(
        links: @issueLinks
        success: (urls_result) =>
          @issueLinks = urls_result.map((element) -> element.url)
          for data from urls_result
            delete data.gid
            @issueData = @issueData.concat(data)

          @renderIssues()
        error: (message = __('Loading legacy issues failed.')) =>
          @showError(message)
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
          return params.error('') if _.isEmpty(data.response)

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
          return params.error('') if _.isEmpty(data.response)

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
      data:  JSON.stringify(ticket_id: params.ticket_id, gids: params.gids, issue_links: params.issue_links)
      success: (data, status, xhr) ->
        params.success(data)
      error: (xhr, status, details) ->
        return if status is 'abort'

        params.error()
    )

  deleteIssue: (issueGids, issueLinks) ->
    if @ticket && @ticket.id
      @saveIssues(
        ticket_id: @ticket.id
        gids: issueGids
        issue_links: issueLinks
        success: =>
          @renderIssues()
        error: (message = __('The issue could not be saved.')) =>
          @showError(App.i18n.translateInline(message))
      )
    else
      @renderIssues()

  deleteIssueByGid: (gid) ->
    @issueGids = _.filter(@issueGids, (element) -> element isnt gid)
    @issueData = _.filter(@issueData, (element) -> element.gid isnt gid)

    @deleteIssue(@issueGids, @issueLinks)

  deleteIssueByUrl: (issueUrl) ->
    @issueLinks = _.filter(@issueLinks, (element) -> element isnt issueUrl)
    @issueData = _.filter(@issueData, (element) -> element.url isnt issueUrl)

    @deleteIssue(@issueGids, @issueLinks)

  showEmpty: ->
    @html("<div>#{App.i18n.translateInline('No linked issues')}</div>")
    @badgeRenderLocal()

  showError: (message) =>
    @error = App.i18n.translateInline(message)
    @renderIssues()

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
