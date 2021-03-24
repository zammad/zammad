class App.SidebarGitIssue extends App.Controller
  provider: '_need_to_be_defined_' # GitLab
  urlPlaceholder: '_need_to_be_defined_' # https://git.example.com/group1/project1/-/issues/1

  constructor: ->
    super
    @issueLinks         = []
    @issueLinkData      = []
    @providerIdentifier = @provider.toLowerCase()

  sidebarItem: =>
    return if !@Config.get("#{@providerIdentifier}_integration")
    @item = {
      name: @providerIdentifier
      badgeCallback: @badgeRender
      sidebarHead: @provider
      sidebarCallback: @reloadIssues
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

    @listIssues()

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
    return if !@badgeEl
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(@metaBadge()))

  linkIssue: =>
    new App.GitIssueLinkModal(
      head: @provider
      placeholder: @urlPlaceholder
      taskKey: @taskKey
      container: @el.closest('.content')
      callback: (link, ui) =>
        @getIssues(
          links: [link]
          success: (result) =>
            if !_.contains(@issueLinks, link)
              @issueLinks.push(result[0].url)
              @issueLinkData = @issueLinkData.concat(result)

            if @ticket && @ticket.id
              @saveIssues(
                ticket_id: @ticket.id
                links: @issueLinks
                success: =>
                  ui.close()
                  @renderIssues()
                error: (message = 'Unable to save issue') =>
                  ui.showAlert(App.i18n.translatePlain(message))
                  form = ui.el.find('.js-result')
                  @formEnable(form)
              )
            else
              ui.close()
              @renderIssues()
          error: (message = 'Unable to load issues') =>
            ui.showAlert(App.i18n.translatePlain(message))
            form = ui.el.find('.js-result')
            @formEnable(form)
        )
    )

  reloadIssues: (el) =>
    if el
      @el = el

    return @renderIssues() if !@ticket

    ticketLinks = @ticket?.preferences?[@providerIdentifier]?.issue_links || []
    return @renderIssues() if _.isEqual(@issueLinks, ticketLinks)

    @issueLinks = ticketLinks
    @listIssues(true)

  renderIssues: =>
    if _.isEmpty(@issueLinkData)
      @showEmpty()
      return

    list = $(App.view('ticket_zoom/sidebar_git_issue')(
      issues: @issueLinkData
    ))
    list.delegate('.js-delete', 'click', (e) =>
      e.preventDefault()
      issueLink = $(e.currentTarget).attr 'data-issue-id'
      @deleteIssue(issueLink)
    )
    @html(list)
    @badgeRenderLocal()

  listIssues: (force = false) =>
    return @renderIssues() if !force && @fetchFullActive && @fetchFullActive > new Date().getTime() - 5000
    @fetchFullActive = new Date().getTime()

    return @renderIssues() if _.isEmpty(@issueLinks)

    @getIssues(
      links: @issueLinks
      success: (result) =>
        @issueLinks    = result.map((element) -> element.url)
        @issueLinkData = result
        @renderIssues()
      error: =>
        @showError(App.i18n.translateInline('Unable to load issues'))
    )

  getIssues: (params) ->
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
          return params.error('Unable to load issues') if _.isEmpty(data.response)

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
      data:  JSON.stringify(ticket_id: params.ticket_id, issue_links: params.links)
      success: (data, status, xhr) ->
        params.success(data)
      error: (xhr, status, details) ->
        return if status is 'abort'

        params.error()
    )

  deleteIssue: (link) ->
    @issueLinks    = _.filter(@issueLinks, (element) -> element isnt link)
    @issueLinkData = _.filter(@issueLinkData, (element) -> element.url isnt link)

    if @ticket && @ticket.id
      @saveIssues(
        ticket_id: @ticket.id
        links: @issueLinks
        success: =>
          @renderIssues()
        error: (message = 'Unable to save issue') =>
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
    return if !@issueLinks
    return if _.isEmpty(@issueLinks)
    args.ticket.preferences ||= {}
    args.ticket.preferences[@providerIdentifier] ||= {}
    args.ticket.preferences[@providerIdentifier].issue_links = @issueLinks
