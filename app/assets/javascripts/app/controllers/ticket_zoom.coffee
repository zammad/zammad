class App.TicketZoom extends App.Controller
  elements:
    '.main':             'main'
    '.ticketZoom':       'ticketZoom'
    '.scrollPageHeader': 'scrollPageHeader'

  events:
    'click .js-submit':   'submit'
    'click .js-bookmark': 'bookmark'
    'click .js-reset':    'reset'

  constructor: (params) ->
    super

    # check authentication
    if !@authenticate()
      App.TaskManager.remove(@task_key)
      return

    @formMeta             = undefined
    @ticket_id            = params.ticket_id
    @article_id           = params.article_id
    @sidebarState         = {}
    @ticketLastAttributes = {}

    # if we are in init task startup, ignore overview_id
    if !params.init
      @overview_id = params.overview_id
    else
      @overview_id = false

    @key = 'ticket::' + @ticket_id
    cache = App.SessionStorage.get(@key)
    if cache
      @load(cache)
    update = =>
      @fetch(@ticket_id, false)

    # check if ticket has beed updated every 30 min
    @interval(update, 1800000, 'pull_check')

    # fetch new data if triggered
    @bind('Ticket:update Ticket:touch', (data) =>

      # check if current ticket has changed
      return if data.id.toString() isnt @ticket_id.toString()

      # check if we already have the request queued
      #@log 'notice', 'TRY', @ticket_id, new Date(data.updated_at), new Date(@ticketUpdatedAtLastCall)
      update = =>
        @fetch(@ticket_id, false)
      if !@ticketUpdatedAtLastCall || ( new Date(data.updated_at).toString() isnt new Date(@ticketUpdatedAtLastCall).toString() )
        @delay( update, 1200, 'ticket-zoom-' + @ticket_id )
    )

    # rerender view, e. g. on langauge change
    @bind('ui:rerender', =>
      @fetch(@ticket_id, true)
    )

  meta: =>

    # default attributes
    meta =
      url: @url()
      id:  @ticket_id

    # set icon and tilte if defined
    if @taskIconClass
      meta.iconClass = @taskIconClass
    if @taskHead
      meta.head = @taskHead

    # set icon and title based on ticket
    if @ticket
      @ticket        = App.Ticket.fullLocal(@ticket.id)
      meta.head      = @ticket.title
      meta.title     = '#' + @ticket.number + ' - ' + @ticket.title
      meta.class     = "task-state-#{ @ticket.getState() }"
      meta.type      = 'task'
      meta.iconTitle = @ticket.iconTitle()
      meta.iconClass = @ticket.iconClass()
    meta

  url: =>
    "#ticket/zoom/#{@ticket_id}"

  show: (params) =>

    @navupdate '#'

    # set all notifications to seen
    App.OnlineNotification.seen('Ticket', @ticket_id)

    # if controller is executed twice, go to latest article (e. g. click on notification)
    if @activeState
      @scrollToBottom()
      return
    @activeState = true

    # start autosave
    @autosaveStart()

    # if ticket is shown the first time
    if !@shown
      @shown = true

      # trigger shown to article
      App.Event.trigger('ui::ticket::shown', { ticket_id: @ticket_id })

      # scroll to end of page
      @scrollToBottom()

    # observe content header position
    @positionPageHeaderStart()

  hide: =>
    @activeState = false

    # stop observing content header position
    @positionPageHeaderStop()

    # stop autosave
    @autosaveStop()

  changed: =>
    return false if !@ticket
    formCurrent = @formParam( @el.find('.edit') )
    ticket      = App.Ticket.find(@ticket_id).attributes()
    modelDiff   = App.Utils.formDiff(formCurrent, ticket)
    return false if !modelDiff || _.isEmpty(modelDiff)
    return true

  release: =>
    @autosaveStop()
    @positionPageHeaderStop()

  fetch: (ticket_id, force) ->
    return if !@Session.get()

    # get data
    @ajax(
      id:    "ticket_zoom_#{ticket_id}"
      type:  'GET'
      url:   "#{@apiPath}/ticket_full/#{ticket_id}"
      processData: true
      success: (data, status, xhr) =>

        # check if ticket has changed
        newTicketRaw = data.assets.Ticket[ticket_id]
        if @ticketUpdatedAtLastCall && !force

          # return if ticket hasnt changed
          return if @ticketUpdatedAtLastCall is newTicketRaw.updated_at

          # notify if ticket changed not by my self
          if newTicketRaw.updated_by_id isnt @Session.get('id')
            App.TaskManager.notify(@task_key)

        # remember current data
        @ticketUpdatedAtLastCall = newTicketRaw.updated_at

        @load(data, force)
        App.SessionStorage(@key, data)

        if !@doNotLog
          @doNotLog = 1
          @recentView('Ticket', ticket_id)

        # scroll to end of page
        if force
          @scrollToBottom()
          @positionPageHeaderUpdate()

      error: (xhr) =>
        statusText = xhr.statusText
        status     = xhr.status
        detail     = xhr.responseText
        #console.log('error', status, statusText)

        # ignore if request is aborted
        if statusText is 'abort'
          return

        # if ticket is already loaded, ignore status "0" - network issues e. g. temp. not connection
        if @ticketUpdatedAtLastCall && status is 0
          console.log('network issues e. g. temp. not connection', status, statusText, detail)
          return

        # show error message
        if status is 401 || statusText is 'Unauthorized'
          @taskHead      = '» ' + App.i18n.translateInline('Unauthorized') + ' «'
          @taskIconClass = 'diagonal-cross'
          @renderScreenUnauthorized(objectName: 'Ticket')
        else if status is 404 || statusText is 'Not Found'
          @taskHead      = '» ' + App.i18n.translateInline('Not Found') + ' «'
          @taskIconClass = 'diagonal-cross'
          @renderScreenNotFound(objectName: 'Ticket')
        else
          @taskHead      = '» ' + App.i18n.translateInline('Error') + ' «'
          @taskIconClass = 'diagonal-cross'

          if !detail
            detail = 'General communication error, maybe internet is not available!'
          @renderScreenError(
            status:     status
            detail:     detail
            objectName: 'Ticket'
          )

        # update taskbar with new meta data
        @metaTaskUpdate()
    )


  load: (data, force) =>

    # remember article ids
    @ticket_article_ids = data.ticket_article_ids

    # remember link
    @links = data.links

    # remember tags
    @tags = data.tags

    # get edit form attributes
    @formMeta = data.form_meta

    # load assets
    App.Collection.loadAssets(data.assets)

    # get data
    @ticket = App.Ticket.fullLocal(@ticket_id)
    @ticket.article = undefined

    # render page
    @render()

  positionPageHeaderStart: =>

    # init header update needed for safari, scroll event is fired
    @positionPageHeaderUpdate()

    # scroll is also fired on window resize, if element scroll is changed
    @main.bind(
      'scroll'
      @positionPageHeaderUpdate
    )

  positionPageHeaderStop: =>
    @main.unbind('scroll', @positionPageHeaderUpdate)

  @scrollHeaderPos: undefined

  positionPageHeaderUpdate: =>
    headerHeight     = @scrollPageHeader.outerHeight()
    mainScrollHeigth = @main.prop('scrollHeight')
    mainHeigth       = @main.height()

    scroll = @main.scrollTop()

    # if page header is not possible to use - mainScrollHeigth to low - hide page header
    if not mainScrollHeigth > mainHeigth + headerHeight
      @scrollPageHeader.css('transform', "translateY(#{-headerHeight}px)")

    if scroll > headerHeight
      scroll = headerHeight

    if scroll is @scrollHeaderPos
      return

    # translateY: headerHeight .. 0
    @scrollPageHeader.css('transform', "translateY(#{scroll - headerHeight}px)")

    @scrollHeaderPos = scroll

  render: =>

    # update taskbar with new meta data
    @metaTaskUpdate()

    @formEnable( @$('.submit') )

    if !@renderDone
      @renderDone = true
      elLocal = $(App.view('ticket_zoom')
        ticket:         @ticket
        nav:            @nav
        isCustomer:     @isRole('Customer')
        scrollbarWidth: App.Utils.getScrollBarWidth()
      )

      new App.TicketZoomOverviewNavigator(
        el:          elLocal.find('.overview-navigator')
        ticket_id:   @ticket.id
        overview_id: @overview_id
      )

      new App.TicketZoomTitle(
        ticket:      @ticket
        overview_id: @overview_id
        el:          elLocal.find('.ticket-title')
        task_key:    @task_key
      )

      new App.TicketZoomMeta(
        ticket: @ticket
        el:     elLocal.find('.ticket-meta')
      )

      new App.TicketZoomAttributeBar(
        ticket:      @ticket
        el:          elLocal.find('.js-attributeBar')
        overview_id: @overview_id
        callback:    @submit
        task_key:    @task_key
      )

      @form_id = App.ControllerForm.formId()

      new App.TicketZoomArticleNew(
        ticket:    @ticket
        ticket_id: @ticket.id
        el:        elLocal.find('.article-new')
        formMeta:  @formMeta
        form_id:   @form_id
        defaults:  @taskGet('article')
        task_key:  @task_key
        ui:        @
      )

      @highligher = new App.TicketZoomHighlighter(
        el:        elLocal.find('.highlighter')
        ticket_id: @ticket.id
      )

      @articleView = new App.TicketZoomArticleView(
        ticket:             @ticket
        el:                 elLocal.find('.ticket-article')
        ui:                 @
        highligher:         @highligher
        ticket_article_ids: @ticket_article_ids
      )

    # rerender whole sidebar if customer or organization has changed
    if @ticketLastAttributes.customer_id isnt @ticket.customer_id || @ticketLastAttributes.organization_id isnt @ticket.organization_id
      new App.WidgetAvatar(
        el:      @$('.ticketZoom-header .js-avatar')
        user_id: @ticket.customer_id
        size:    50
      )
      if elLocal
        el = elLocal
      else
        el = @el
      @sidebar = new App.TicketZoomSidebar(
        el:           el.find('.tabsSidebar')
        sidebarState: @sidebarState
        ticket:       @ticket
        taskGet:      @taskGet
        task_key:     @task_key
        tags:         @tags
        links:        @links
        formMeta:     @formMeta
      )

    # render init page
    if elLocal
      @html elLocal

    # show article
    else
      @articleView.execute(
        ticket_article_ids: @ticket_article_ids
      )

    # scroll to article if given
    if @article_id && document.getElementById( 'article-' + @article_id )
      offset = document.getElementById( 'article-' + @article_id ).offsetTop
      offset = offset - 45
      scrollTo = ->
        @scrollTo( 0, offset )
      @delay( scrollTo, 100, false )

    @ticketLastAttributes = @ticket.attributes()

    if @shown && !@initDone
      @initDone = true

      # scroll to end of page
      @scrollToBottom()

      # observe content header position
      @positionPageHeaderStart()

      # trigger shown if init shown render
      App.Event.trigger('ui::ticket::shown', { ticket_id: @ticket_id })

  scrollToBottom: =>
    @main.scrollTop( @main.prop('scrollHeight') )

  autosaveStop: =>
    @autosaveLast = {}
    @clearInterval('autosave')

  autosaveStart: =>
    if !@autosaveLast
      @autosaveLast = @taskGet()
    update = =>
      #console.log('AR', @ticket_id, @ticket, @formParam( @el.find('.article-add') ) )
      return if !@ticket
      currentStoreTicket = @ticket.attributes()
      delete currentStoreTicket.article
      currentStore  =
        ticket:  currentStoreTicket
        article:
          to:          ''
          cc:          ''
          type:        'note'
          body:        ''
          internal:    ''
          in_reply_to: ''
      currentParams =
        ticket:  @formParam( @el.find('.edit') )
        article: @formParam( @el.find('.article-add') )

      # add attachments if exist
      attachmentCount = @$('.article-add .textBubble .attachments .attachment').length
      if attachmentCount > 0
        currentParams.article.attachments = true
      else
        delete currentParams.article.attachments

      #console.log('lll', currentStore)
      # remove not needed attributes
      delete currentParams.article.form_id

      # get diff of model
      modelDiff =
        ticket:  App.Utils.formDiff( currentParams.ticket, currentStore.ticket )
        article: App.Utils.formDiff( currentParams.article, currentStore.article )
      #console.log('modelDiff', modelDiff)

      # get diff of last save
      changedBetweenLastSave = _.isEqual(currentParams, @autosaveLast)
      if !changedBetweenLastSave
        #console.log('model DIFF ', modelDiff)

        @autosaveLast = clone(currentParams)
        @markFormDiff(modelDiff)

        @taskUpdateAll(modelDiff)
    @interval(update, 2800, 'autosave')

  markFormDiff: (diff = {}) =>
    ticketForm    = @$('.edit')
    ticketSidebar = @$('.tabsSidebar-tab[data-tab="ticket"]')
    articleForm   = @$('.article-add')
    resetButton   = @$('.js-reset')

    params         = {}
    params.ticket  = @formParam( ticketForm )
    params.article = @formParam( articleForm )
    #console.log('markFormDiff', diff, params)

    # clear all changes
    if _.isEmpty(diff.ticket) && _.isEmpty(diff.article)
      ticketSidebar.removeClass('is-changed')
      ticketForm.removeClass('form-changed')
      ticketForm.find('.form-group').removeClass('is-changed')
      resetButton.addClass('hide')

    # set changes
    else
      ticketForm.addClass('form-changed')
      if !_.isEmpty(diff.ticket)
        ticketSidebar.addClass('is-changed')
      else
        ticketSidebar.removeClass('is-changed')
      for currentKey, currentValue of params.ticket
        element = @$('.edit [name="' + currentKey + '"]').parents('.form-group')
        if !element.get(0)
          element = @$('.edit [data-name="' + currentKey + '"]').parents('.form-group')
        if currentKey of diff.ticket
          if !element.hasClass('is-changed')
            element.addClass('is-changed')
        else
          if element.hasClass('is-changed')
            element.removeClass('is-changed')

      resetButton.removeClass('hide')

  submit: (e, macro = {}) =>
    e.stopPropagation()
    e.preventDefault()

    taskAction = @$('.js-secondaryActionButtonLabel').data('type')

    ticketParams = @formParam( @$('.edit') )

    # validate ticket
    ticket = App.Ticket.fullLocal( @ticket.id )

    # reset article - should not be resubmited on next ticket update
    ticket.article = undefined

    # update ticket attributes
    for key, value of ticketParams
      ticket[key] = value

    # apply macro
    for key, content of macro
      attributes = key.split('.')
      if attributes[0] is 'ticket'

        # apply tag changes
        if attributes[1] is 'tags'
          if @sidebar && @sidebar.tagWidget
            tags = content.value.split(',')
            for tag in tags
              if content.operator is 'remove'
                @sidebar.tagWidget.remove(tag)
              else
                @sidebar.tagWidget.add(tag)

        # apply direct value changes
        else
          ticket[attributes[1]] = content.value

    # set defaults
    if !@isRole('Customer')
      if !ticket['owner_id']
        ticket['owner_id'] = 1

    # check if title exists
    if !ticket['title']
      alert( App.i18n.translateContent('Title needed') )
      return

    # submit ticket & article
    @log 'notice', 'update ticket', ticket

    # disable form
    @formDisable(e)

    # stop autosave
    @autosaveStop()

    # validate ticket
    errors = ticket.validate(
      screen: 'edit'
    )
    if errors
      @log 'error', 'update', errors
      @formValidate(
        form:   @$('.edit')
        errors: errors
        screen: 'edit'
      )
      @formEnable(e)
      @autosaveStart()
      return

    console.log('ticket validateion ok')

    # validate article
    articleParams = @formParam( @$('.article-add') )
    console.log 'submit article', articleParams

    # check if attachment exists but no body
    attachmentCount = @$('.article-add .textBubble .attachments .attachment').length
    if !articleParams['body'] && attachmentCount > 0
      if !confirm( App.i18n.translateContent('Please fill also some text in!') )
        @formEnable(e)
        @autosaveStart()
        return

    if articleParams['body']
      articleParams.from         = @Session.get().displayName()
      articleParams.ticket_id    = ticket.id
      articleParams.form_id      = @form_id
      articleParams.content_type = 'text/html'

      if !articleParams['internal']
        articleParams['internal'] = false

      if @isRole('Customer')
        sender                  = App.TicketArticleSender.findByAttribute( 'name', 'Customer' )
        type                    = App.TicketArticleType.findByAttribute( 'name', 'web' )
        articleParams.type_id   = type.id
        articleParams.sender_id = sender.id
      else
        sender                  = App.TicketArticleSender.findByAttribute( 'name', 'Agent' )
        articleParams.sender_id = sender.id
        type                    = App.TicketArticleType.findByAttribute( 'name', articleParams['type'] )
        articleParams.type_id   = type.id

      article = new App.TicketArticle
      for key, value of articleParams
        article[key] = value

      # validate email params
      if type.name is 'email'

        # check if recipient exists
        if !articleParams['to'] && !articleParams['cc']
          alert( App.i18n.translateContent('Need recipient in "To" or "Cc".') )
          @formEnable(e)
          @autosaveStart()
          return

        # check if message exists
        if !articleParams['body']
          alert( App.i18n.translateContent('Text needed') )
          @formEnable(e)
          @autosaveStart()
          return

      # check attachment
      if articleParams['body']
        if App.Utils.checkAttachmentReference( articleParams['body'] ) && attachmentCount < 1
          if !confirm( App.i18n.translateContent('You use attachment in text but no attachment is attached. Do you want to continue?') )
            @formEnable(e)
            @autosaveStart()
            return

      article.load(articleParams)
      errors = article.validate()
      if errors
        @log 'error', 'update article', errors
        @formValidate(
          form:   @$('.article-add')
          errors: errors
          screen: 'edit'
        )
        @formEnable(e)
        @autosaveStart()
        return

      ticket.article = article

    # submit changes
    ticket.save(
      done: (r) =>

        # reset article - should not be resubmited on next ticket update
        ticket.article = undefined

        # reset form after save
        @reset()

        if taskAction is 'closeNextInOverview'
          if @overview_id
            current_position = 0
            overview = App.Overview.find(@overview_id)
            list = App.OverviewCollection.get(overview.link)
            for ticket_id in list.ticket_ids
              current_position += 1
              if ticket_id is @ticket_id
                next = list.ticket_ids[current_position]
                if next
                  # close task
                  App.TaskManager.remove(@task_key)

                  # open task via task manager to get overview information
                  App.TaskManager.execute(
                    key:        'Ticket-' + next
                    controller: 'TicketZoom'
                    params:
                      ticket_id:   next
                      overview_id: @overview_id
                    show:       true
                  )
                  @navigate "ticket/zoom/#{next}"
                  return

          # fallback, close task
          taskAction = 'closeTab'

        if taskAction is 'closeTab'
          App.TaskManager.remove(@task_key)
          nextTaskUrl = App.TaskManager.nextTaskUrl()
          if nextTaskUrl
            @navigate nextTaskUrl
            return

          @navigate '#'
          return

        @autosaveStart()

        App.TaskManager.mute(@task_key)

        @fetch(ticket.id, true)

        # enable form
        @formEnable(e)
    )

  bookmark: (e) ->
    $(e.currentTarget).find('.bookmark.icon').toggleClass('filled')

  reset: (e) =>
    if e
      e.preventDefault()

    # reset task
    @taskReset()

    # reset/delete uploaded attachments
    App.Ajax.request(
      type:  'DELETE'
      url:   App.Config.get('api_path') + '/ticket_attachment_upload'
      data:  JSON.stringify( { form_id: @form_id } )
      processData: false
    )

    # reset edit ticket / reset new article
    App.Event.trigger('ui::ticket::taskReset', { ticket_id: @ticket.id })

    # hide reset button
    @$('.js-reset').addClass('hide')

    # remove change flag on tab
    @$('.tabsSidebar-tab[data-tab="ticket"]').removeClass('is-changed')

  taskGet: (area) =>
    return {} if !App.TaskManager.get(@task_key)
    @localTaskData = App.TaskManager.get(@task_key).state || {}
    if area
      if !@localTaskData[area]
        @localTaskData[area] = {}
      return @localTaskData[area]
    if !@localTaskData
      @localTaskData = {}
    @localTaskData

  taskUpdate: (area, data) =>
    @localTaskData[area] = data
    App.TaskManager.update(@task_key, { 'state': @localTaskData })

  taskUpdateAll: (data) =>
    @localTaskData = data
    App.TaskManager.update(@task_key, { 'state': @localTaskData })

  # reset task state
  taskReset: =>
    @localTaskData =
      ticket:  {}
      article: {}
    App.TaskManager.update(@task_key, { 'state': @localTaskData })

class TicketZoomRouter extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      ticket_id:  params.ticket_id
      article_id: params.article_id
      nav:        params.nav
      shown:      true

    App.TaskManager.execute(
      key:        'Ticket-' + @ticket_id
      controller: 'TicketZoom'
      params:     clean_params
      show:       true
    )

App.Config.set( 'ticket/zoom/:ticket_id', TicketZoomRouter, 'Routes' )
App.Config.set( 'ticket/zoom/:ticket_id/nav/:nav', TicketZoomRouter, 'Routes' )
App.Config.set( 'ticket/zoom/:ticket_id/:article_id', TicketZoomRouter, 'Routes' )
