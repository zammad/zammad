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
      App.TaskManager.remove( @task_key )
      return

    @navupdate '#'

    @form_meta            = undefined
    @ticket_id            = params.ticket_id
    @article_id           = params.article_id
    @sidebarState         = {}
    @ticketLastAttributes = {}

    # if we are in init task startup, ognore overview_dd
    if !params.init
      @overview_id = params.overview_id
    else
      @overview_id = false

    @key = 'ticket::' + @ticket_id
    cache = App.Store.get( @key )
    if cache
      @load(cache)
    update = =>
      @fetch( @ticket_id, false )

    # check if ticket has beed updated every 30 min
    @interval( update, 1800000, 'pull_check' )

    # fetch new data if triggered
    @bind(
      'Ticket:update'
      (data) =>

        # check if current ticket has changed
        if data.id.toString() is @ticket_id.toString()

          # check if we already have the request queued
          #@log 'notice', 'TRY', @ticket_id, new Date(data.updated_at), new Date(@ticketUpdatedAtLastCall)
          update = =>
            @fetch( @ticket_id, false )
          if !@ticketUpdatedAtLastCall || ( new Date(data.updated_at).toString() isnt new Date(@ticketUpdatedAtLastCall).toString() )
            @delay( update, 1800, 'ticket-zoom-' + @ticket_id )
    )

    # rerender view, e. g. on langauge change
    @bind 'ui:rerender', =>
      return if !@authenticate(true)
      @render(true)

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
      @ticket        = App.Ticket.fullLocal( @ticket.id )
      meta.head      = @ticket.title
      meta.title     = '#' + @ticket.number + ' - ' + @ticket.title
      meta.class     = "level-#{@ticket.level()}"
      meta.iconClass = 'priority'
    meta

  url: =>
    '#ticket/zoom/' + @ticket_id

  show: (params) =>
    return if @activeState
    @activeState = true

    # set see more options
    @setSeeMore()

    App.OnlineNotification.seen( 'Ticket', @ticket_id )
    @navupdate '#'
    @positionPageHeaderStart()

  hide: =>
    @activeState = false
    @positionPageHeaderStop()

  changed: =>
    return false if !@ticket
    formCurrent = @formParam( @el.find('.edit') )
    ticket      = App.Ticket.find(@ticket_id).attributes()
    modelDiff   = App.Utils.formDiff( formCurrent, ticket  )
    return false if !modelDiff || _.isEmpty( modelDiff )
    return true

  release: =>
    @autosaveStop()
    @positionPageHeaderStop()

  fetch: (ticket_id, force) ->

    return if !@Session.get()

    # get data
    @ajax(
      id:    'ticket_zoom_' + ticket_id
      type:  'GET'
      url:   @apiPath + '/ticket_full/' + ticket_id
      processData: true
      success: (data, status, xhr) =>

        # check if ticket has changed
        newTicketRaw = data.assets.Ticket[ticket_id]
        if @ticketUpdatedAtLastCall && !force

          # return if ticket hasnt changed
          return if @ticketUpdatedAtLastCall is newTicketRaw.updated_at

          # notify if ticket changed not by my self
          if newTicketRaw.updated_by_id isnt @Session.get('id')
            App.TaskManager.notify( @task_key )

        # remember current data
        @ticketUpdatedAtLastCall = newTicketRaw.updated_at

        @load(data, force)
        App.Store.write( @key, data )

        if !@doNotLog
          @doNotLog = 1
          @recentView( 'Ticket', ticket_id )

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
          @taskIconClass = 'error'
          @html App.view('generic/error/unauthorized')( objectName: 'Ticket' )
        else if status is 404 || statusText is 'Not Found'
          @taskHead      = '» ' + App.i18n.translateInline('Not Found') + ' «'
          @taskIconClass = 'error'
          @html App.view('generic/error/not_found')( objectName: 'Ticket' )
        else
          @taskHead      = '» ' + App.i18n.translateInline('Error') + ' «'
          @taskIconClass = 'error'

          if !detail
            detail = 'General communication error, maybe internet is not available!'
          @html App.view('generic/error/generic')(
            status:     status
            detail:     detail
            objectName: 'Ticket'
          )

        # update current task title
        App.Event.trigger 'task:render'
    )


  load: (data, force) =>

    # remember article ids
    @ticket_article_ids = data.ticket_article_ids

    # remember link
    @links = data.links

    # remember tags
    @tags = data.tags

    # get edit form attributes
    @form_meta = data.form_meta

    # load assets
    App.Collection.loadAssets( data.assets )

    # get data
    @ticket = App.Ticket.fullLocal( @ticket_id )
    @ticket.article = undefined

    # render page
    @render(force)

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

  positionPageHeaderUpdate: =>
    headerHeight     = @scrollPageHeader.outerHeight()
    mainScrollHeigth = @main.prop('scrollHeight')
    mainHeigth       = @main.height()

    # if page header is possible to use, show page header
    top = 0
    if mainScrollHeigth > mainHeigth + headerHeight
      scroll = @main.scrollTop()
      if scroll <= headerHeight
        top = (scroll - headerHeight)

    # if page header is not possible to use - mainScrollHeigth to low - hide page header
    else
      top = -headerHeight

    @scrollPageHeader.css('transform', "translateY(#{top}px)")

  render: (force) =>

    # update taskbar with new meta data
    App.Event.trigger 'task:render'
    @formEnable( @$('.submit') )

    if force || !@renderDone
      @renderDone = true
      @html App.view('ticket_zoom')(
        ticket:     @ticket
        nav:        @nav
        isCustomer: @isRole('Customer')
      )

      new OverviewNavigator(
        el:          @$('.overview-navigator')
        ticket_id:   @ticket.id
        overview_id: @overview_id
      )

      new TicketTitle(
        ticket:      @ticket
        overview_id: @overview_id
        el:          @el.find('.ticket-title')
        task_key:    @task_key
      )

      new TicketMeta(
        ticket: @ticket
        el:     @el.find('.ticket-meta')
      )

      @form_id = App.ControllerForm.formId()

      new Edit(
        ticket:     @ticket
        el:         @el.find('.ticket-edit')
        #el:         @el.find('.edit')
        form_meta:  @form_meta
        form_id:    @form_id
        defaults:   @taskGet('article')
        ui:         @
      )

    # rerender whole sidebar if customer or organization has changed
    if @ticketLastAttributes.customer_id isnt @ticket.customer_id || @ticketLastAttributes.organization_id isnt @ticket.organization_id
      new App.WidgetAvatar(
        el:       @$('.page-header .js-avatar')
        user_id:  @ticket.customer_id
        size:     50
      )
      new TicketSidebar(
        el:           @el.find('.tabsSidebar')
        sidebarState: @sidebarState
        ticket:       @ticket
        taskGet:      @taskGet
        task_key:     @task_key
        tags:         @tags
        links:        @links
        form_meta:    @form_meta
      )

    # show article
    new ArticleView(
      ticket:             @ticket
      ticket_article_ids: @ticket_article_ids
      el:                 @el.find('.ticket-article')
      ui:                 @
    )

    # set see more options
    @setSeeMore()

    # scroll to article if given
    if @article_id && document.getElementById( 'article-' + @article_id )
      offset = document.getElementById( 'article-' + @article_id ).offsetTop
      offset = offset - 45
      scrollTo = ->
        @scrollTo( 0, offset )
      @delay( scrollTo, 100, false )

    @autosaveStart()

    @scrollToBottom()

    @positionPageHeaderStart()

    @ticketLastAttributes = @ticket.attributes()

  # set see more options
  setSeeMore: =>
    maxHeight = 560
    @$('.textBubble-content').each( (index) ->
      bubble    = $( @ )

      # reset bubble heigth and "see more" opacity
      bubble.css('height', '')
      bubble.parent().find('.textBubble-overflowContainer').css('opacity', '')

      # remember offset of "see more"
      offsetTop = bubble.find('.js-signatureMarker').position()

      # remember bubble heigth
      heigth = bubble.height()
      if offsetTop
        bubble.attr('data-height', heigth)
        bubble.css('height', "#{offsetTop.top + 30}px")
        bubble.parent().find('.textBubble-overflowContainer').removeClass('hide')
      else if heigth > maxHeight
        bubble.attr('data-height', heigth)
        bubble.css('height', "#{maxHeight}px")
        bubble.parent().find('.textBubble-overflowContainer').removeClass('hide')
      else
        bubble.parent().find('.textBubble-overflowContainer').addClass('hide')
    )

  scrollToBottom: =>
    @main.scrollTop( @main.prop('scrollHeight') )

  autosaveStop: =>
    @autosaveLast = {}
    @clearInterval( 'autosave' )

  autosaveStart: =>
    if !@autosaveLast
      @autosaveLast = @taskGet()
    update = =>
      #console.log('AR', @formParam( @el.find('.article-add') ) )
      currentStore  =
        ticket:  @ticket.attributes()
        article: {
          to:       ''
          cc:       ''
          type:     'note'
          body:     ''
          internal: ''
        }
      currentParams =
        ticket:  @formParam( @el.find('.edit') )
        article: @formParam( @el.find('.article-add') )
      #console.log('lll', currentStore)
      # remove not needed attributes
      delete currentParams.article.form_id

      # get diff of model
      modelDiff =
        ticket:  App.Utils.formDiff( currentParams.ticket, currentStore.ticket )
        article: App.Utils.formDiff( currentParams.article, currentStore.article )
      #console.log('modelDiff', modelDiff)

      # get diff of last save
      changedBetweenLastSave = _.isEqual(currentParams, @autosaveLast )
      if !changedBetweenLastSave
        console.log('model DIFF ', modelDiff)

        @autosaveLast = clone(currentParams)
        @markFormDiff( modelDiff )

        @taskUpdateAll( modelDiff )
    @interval( update, 3000, 'autosave' )

  markFormDiff: (diff = {}) =>
    ticketForm    = @$('.edit')
    ticketSidebar = @$('.tabsSidebar-tab[data-tab="ticket"]')
    articleForm   = @$('.article-add')
    resetButton   = @$('.js-reset')

    params         = {}
    params.ticket  = @formParam( ticketForm )
    params.article = @formParam( articleForm )
    console.log('markFormDiff', diff, params)

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


  submit: (e) =>
    e.stopPropagation()
    e.preventDefault()
    ticketParams = @formParam( @$('.edit') )

    # validate ticket
    ticket = App.Ticket.fullLocal( @ticket.id )

    # reset article - should not be resubmited on next ticket update
    ticket.article = undefined

    # update ticket attributes
    for key, value of ticketParams
      ticket[key] = value

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
    console.log "submit article", articleParams
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
        if App.Utils.checkAttachmentReference( articleParams['body'] )
          if @$('.article-add .textBubble .attachments .attachment').length < 1
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
        @renderDone = false

        # reset article - should not be resubmited on next ticket update
        ticket.article = undefined

        # reset form after save
        @reset()

        App.TaskManager.mute( @task_key )

        @fetch( ticket.id, true )
    )

  bookmark: (e) =>
    $(e.currentTarget).find('.bookmark.icon').toggleClass('filled')

  reset: (e) =>
    if e
      e.preventDefault()

    # reset task
    @taskReset()

    # reset edit ticket / reset new article
    App.Event.trigger('ui::ticket::taskReset', { ticket_id: @ticket.id } )

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
    App.TaskManager.update( @task_key, { 'state': @localTaskData })

  taskUpdateAll: (data) =>
    @localTaskData = data
    App.TaskManager.update( @task_key, { 'state': @localTaskData })

  # reset task state
  taskReset: =>
    @localTaskData =
      ticket:  {}
      article: {}
    App.TaskManager.update( @task_key, { 'state': @localTaskData })

class TicketSidebar extends App.Controller
  constructor: ->
    super
    ticket       = App.Ticket.fullLocal( @ticket.id )
    @subscribeId = ticket.subscribe(@render)
    @render(ticket)

  release: =>
    App.Ticket.unsubscribe( @subscribeId )

  render: (ticket) =>

    editTicket = (el) =>
      el.append('<form class="edit"></form>')
      @editEl = el

      show = (ticket) =>
        el.find('.edit').html('')

        defaults   = ticket.attributes()
        task_state = @taskGet('ticket')
        modelDiff  = App.Utils.formDiff( task_state, defaults )
        #if @isRole('Customer')
        #  delete defaults['state_id']
        #  delete defaults['state']
        if !_.isEmpty( task_state )
          defaults = _.extend( defaults, task_state )

        new App.ControllerForm(
          el:       el.find('.edit')
          model:    App.Ticket
          screen:   'edit'
          params:   App.Ticket.find(ticket.id)
          handlers: [
            @ticketFormChanges
          ]
          filter:    @form_meta.filter
          params:    defaults
          #bookmarkable: true
        )
        #console.log('Ichanges', modelDiff, task_state, ticket.attributes())
        #@markFormDiff( modelDiff )

      show(ticket)
      @bind(
        'ui::ticket::taskReset'
        (data) =>
          if data.ticket_id is ticket.id
            show(ticket)
      )

      if !@isRole('Customer')
        el.append('<div class="tags"></div>')
        new App.WidgetTag(
          el:          el.find('.tags')
          object_type: 'Ticket'
          object:      ticket
          tags:        @tags
        )
        el.append('<div class="links"></div>')
        new App.WidgetLink(
          el:          el.find('.links')
          object_type: 'Ticket'
          object:      ticket
          links:       @links
        )

    showTicketHistory = =>
      new App.TicketHistory(
        ticket_id: ticket.id
        container: @el.closest('.content')
      )
    showTicketMerge = =>
      new App.TicketMerge(
        ticket:    ticket
        task_key:  @task_key
        container: @el.closest('.content')
      )
    changeCustomer = (e, el) =>
      new App.TicketCustomer(
        ticket:    ticket
        container: @el.closest('.content')
      )
    @sidebarItems = [
      {
        head:     'Ticket'
        name:     'ticket'
        icon:     'message'
        callback: editTicket
      }
    ]
    if !@isRole('Customer')
      @sidebarItems[0]['actions'] = [
        {
          name:     'ticket-history'
          title:    'History'
          callback: showTicketHistory
        },
        {
          name:     'ticket-merge'
          title:    'Merge'
          callback: showTicketMerge
        },
        {
          title:    'Change Customer'
          name:     'customer-change'
          callback: changeCustomer
        },
      ]
    if !@isRole('Customer')
      editCustomer = (e, el) =>
        new App.ControllerGenericEdit(
          id: ticket.customer_id
          genericObject: 'User'
          screen: 'edit'
          pageData:
            title:   'Users'
            object:  'User'
            objects: 'Users'
          container: @el.closest('.content')
        )
      showCustomer = (el) =>
        new App.WidgetUser(
          el:       el
          user_id:  ticket.customer_id
        )
      @sidebarItems.push {
        head:    'Customer'
        name:    'customer'
        icon:    'person'
        actions: [
          {
            title:    'Change Customer'
            name:     'customer-change'
            callback: changeCustomer
          },
          {
            title:    'Edit Customer'
            name:     'customer-edit'
            callback: editCustomer
          },
        ]
        callback: showCustomer
      }
      if ticket.organization_id
        editOrganization = (e, el) =>
          new App.ControllerGenericEdit(
            id: ticket.organization_id,
            genericObject: 'Organization'
            pageData:
              title:   'Organizations'
              object:  'Organization'
              objects: 'Organizations'
            container: @el.closest('.content')
          )
        showOrganization = (el) =>
          new App.WidgetOrganization(
            el:              el
            organization_id: ticket.organization_id
          )
        @sidebarItems.push {
          head: 'Organization'
          name: 'organization'
          icon: 'group'
          actions: [
            {
              title:    'Edit Organization'
              name:     'organization-edit'
              callback: editOrganization
            },
          ]
          callback: showOrganization
        }
    new App.Sidebar(
      el:           @el
      sidebarState: @sidebarState
      items:        @sidebarItems
    )

class TicketTitle extends App.Controller
  events:
    'blur .ticket-title-update': 'update'

  constructor: ->
    super

    @ticket      = App.Ticket.fullLocal( @ticket.id )
    @subscribeId = @ticket.subscribe(@render)
    @render(@ticket)

  render: (ticket) =>

    # check if render is needed
    if @lastTitle && @lastTitle is ticket.title
      return
    @lastTitle = ticket.title

    @html App.view('ticket_zoom/title')(
      ticket: ticket
    )

    @$('.ticket-title-update').ce({
      mode:      'textonly'
      multiline: false
      maxlength: 250
    })

  update: (e) =>
    title = $(e.target).ceg() || ''

    # update title
    if title isnt @ticket.title
      @ticket.title = title

      # reset article - should not be resubmited on next ticket update
      @ticket.article = undefined

      @ticket.save()

      App.TaskManager.mute( @task_key )

      # update taskbar with new meta data
      App.Event.trigger 'task:render'

  release: =>
    App.Ticket.unsubscribe( @subscribeId )

class OverviewNavigator extends App.Controller
  events:
    'click a': 'open'

  constructor: ->
    super

    # rebuild overview navigator if overview has changed
    @bind 'ticket_overview_rebuild', (data) =>
      execute = =>
        @render()
      @delay(execute, 600, 'overview-navigator')

    @render()

  render: (overview) =>
    if !@overview_id
      @html('')
      return

    # get overview data
    worker = App.TaskManager.worker( 'TicketOverview' )
    return if !worker
    overview = worker.overview(@overview_id)
    return if !overview
    current_position = 0
    next             = false
    previous         = false
    for ticket_id in overview.ticket_ids
      current_position += 1
      next              = overview.ticket_ids[current_position]
      previous          = overview.ticket_ids[current_position-2]
      break if ticket_id is @ticket_id

    # get next/previous ticket
    if next
      next = App.Ticket.find(next)
    if previous
      previous = App.Ticket.find(previous)

    @html App.view('ticket_zoom/overview_navigator')(
      title:            overview.overview.name
      total_count:      overview.tickets_count
      current_position: current_position
      next:             next
      previous:         previous
    )

  open: (e) =>
    e.preventDefault()

    # get requested object and location
    id  = $(e.target).data('id')
    url = $(e.target).attr('href')
    if !id
      id  = $(e.target).closest('a').data('id')
      url = $(e.target).closest('a').attr('href')

    # return if we are unable to get id
    return if !id

    # open task via task manager to get overview information
    App.TaskManager.execute(
      key:        'Ticket-' + id
      controller: 'TicketZoom'
      params:
        ticket_id:   id
        overview_id: @overview_id
      show:       true
    )
    @navigate url

class TicketMeta extends App.Controller
  constructor: ->
    super

    @ticket      = App.Ticket.fullLocal( @ticket.id )
    @subscribeId = @ticket.subscribe(@render)
    @render(@ticket)

  render: (ticket) =>
    @html App.view('ticket_zoom/meta')(
      ticket:     ticket
      isCustomer: @isRole('Customer')
    )

    # show frontend times
    @frontendTimeUpdate()

  release: =>
    App.Ticket.unsubscribe( @subscribeId )

class Edit extends App.Controller
  elements:
    '.js-textarea':                       'textarea'
    '.attachmentPlaceholder':             'attachmentPlaceholder'
    '.attachmentPlaceholder-inputHolder': 'attachmentInputHolder'
    '.attachmentPlaceholder-hint':        'attachmentHint'
    '.article-add':                       'ticketEdit'
    '.attachments':                       'attachmentsHolder'
    '.attachmentUpload':                  'attachmentUpload'
    '.attachmentUpload-progressBar':      'progressBar'
    '.js-percentage':                     'progressText'
    '.js-cancel':                         'cancelContainer'
    '.textBubble':                       'textBubble'
    '.editControls-item':                 'editControlItem'
    #'.editControls':                     'editControls'
    #'.recipient-picker':                 'recipientPicker'
    #'.recipient-list':                   'recipientList'
    #'.recipient-list .list-arrow':       'recipientListArrow'

  events:
    'click .visibility-toggle':    'toggleVisibility'
    'click .pop-selectable':       'selectArticleType'
    'click .pop-selected':         'showSelectableArticleType'
    'click .recipient-picker':     'toggle_recipients'
    'click .recipient-list':       'stopPropagation'
    'click .list-entry-type div':  'change_type'
    'submit .recipient-list form': 'add_recipient'
    'focus .js-textarea':          'open_textarea'
    'input .js-textarea':          'detect_empty_textarea'
    #'dragenter':                  'onDragenter'
    #'dragleave':                  'onDragleave'
    #'drop':                       'onFileDrop'
    #'change input[type=file]':    'onFilePick'

  constructor: ->
    super

    # gets referenced in @setArticleType
    @type = @defaults['type'] || 'note'
    @articleTypes = [
      {
        name:       'note'
        icon:       'note'
        attributes: []
      },
      {
        name:       'email'
        icon:       'email'
        attributes: ['to','cc']
      },
      {
        name:       'facebook'
        icon:       'facebook'
        attributes: []
      },
      {
        name:       'twitter'
        icon:       'twitter'
        attributes: []
      },
      {
        name:       'phone'
        icon:       'phone'
        attributes: []
      },
    ]
    if @isRole('Customer')
      @type = 'note'
      @articleTypes = [
        {
          name:       'note'
          icon:       'note'
          attributes: []
        },
      ]

    @textareaHeight =
      open:   148
      closed: 20

    @dragEventCounter = 0
    @attachments      = []

    @render()

    if @defaults.body or @isIE10()
      @open_textarea(null, true)

    @bind(
      'ui::ticket::setArticleType'
      (data) =>
        if data.ticket.id is @ticket.id
          #@setArticleType(data.type.name)

          @open_textarea(null, true)
          for key, value of data.article
            if key is 'body'
              @$('[data-name="' + key + '"]').html(value)
            else
              @$('[name="' + key + '"]').val(value)

          # preselect article type
          @setArticleType( 'email' )
    )

    @bind(
      'ui::ticket::taskReset'
      (data) =>
        if data.ticket_id is @ticket.id
          @render()
    )

  isIE10: ->
    Function('/*@cc_on return document.documentMode===10@*/')()

  stopPropagation: (e) ->
    e.stopPropagation()

  release: =>
    if @subscribeIdTextModule
      App.Ticket.unsubscribe(@subscribeIdTextModule)

  render: ->

    ticket = App.Ticket.fullLocal( @ticket.id )

    @html App.view('ticket_zoom/edit')(
      ticket:       ticket
      articleTypes: @articleTypes
      article:      @defaults
      isCustomer:   @isRole('Customer')
    )
    @setArticleType(@type)

    new App.WidgetAvatar(
      el:       @$('.js-avatar')
      user_id:  App.Session.get('id')
      size:     40
      position: 'right'
      class:    'zIndex-5'
    )

    configure_attributes = [
      { name: 'customer_id', display: 'Recipients', tag: 'user_autocompletion', null: false, placeholder: 'Enter Person or Organization/Company', minLengt: 2, disableCreateUser: false },
    ]

    controller = new App.ControllerForm(
      el: @$('.recipients')
      model:
        configure_attributes: configure_attributes,
    )

    @$('[data-name="body"]').ce({
      mode:      'richtext'
      multiline: true
      maxlength: 5000
    })

    html5Upload.initialize(
      uploadUrl:              App.Config.get('api_path') + '/ticket_attachment_upload',
      dropContainer:          @el.get(0),
      cancelContainer:        @cancelContainer,
      inputField:             @$('.article-attachment input').get(0),
      key:                    'File',
      data:                   { form_id: @form_id },
      maxSimultaneousUploads: 1,
      onFileAdded:            (file) =>

        file.on(

          onStart: =>
            @attachmentPlaceholder.addClass('hide')
            @attachmentUpload.removeClass('hide')
            @cancelContainer.removeClass('hide')
            console.log('upload start')

          onAborted: =>
            @attachmentPlaceholder.removeClass('hide')
            @attachmentUpload.addClass('hide')

          # Called after received response from the server
          onCompleted: (response) =>

            response = JSON.parse(response)
            @attachments.push response.data

            @attachmentPlaceholder.removeClass('hide')
            @attachmentUpload.addClass('hide')

            @renderAttachment(response.data)
            console.log('upload complete', response.data )

          # Called during upload progress, first parameter
          # is decimal value from 0 to 100.
          onProgress: (progress, fileSize, uploadedBytes) =>
            @progressBar.width(parseInt(progress) + "%")
            @progressText.text(parseInt(progress))
            # hide cancel on 90%
            if parseInt(progress) >= 90
              @cancelContainer.addClass('hide')
            console.log('uploadProgress ', parseInt(progress))
        )
    )

    # show text module UI
    if !@isRole('Customer')
      textModule = new App.WidgetTextModule(
        el:       @$('.js-textarea').parent()
        data:
          ticket: ticket
      )
      callback = (ticket) =>
        textModule.reload(
          ticket: ticket
        )
      @subscribeIdTextModule = ticket.subscribe( callback )

  toggle_recipients: =>
    if !@pickRecipientsCatcher
      @show_recipients()
    else
      @hide_recipients()

  show_recipients: ->
    padding = 15

    @recipientPicker.addClass('is-open')
    @recipientList.removeClass('hide')

    pickerDimensions = @recipientPicker.get(0).getBoundingClientRect()
    availableHeight = @recipientPicker.scrollParent().outerHeight()

    top = pickerDimensions.height/2 - @recipientList.height()/2
    bottomDistance = availableHeight - padding - (pickerDimensions.top + top + @recipientList.height())

    if bottomDistance < 0
      top += bottomDistance

    arrowCenter = -top + pickerDimensions.height/2

    @recipientListArrow.css('top', arrowCenter)
    @recipientList.css('top', top)

    $.Velocity.hook(@recipientList, 'transformOriginX', "0")
    $.Velocity.hook(@recipientList, 'transformOriginY', "#{ arrowCenter }px")

    @recipientList.velocity
      properties:
        scale: [ 1, 0 ]
        opacity: [ 1, 0 ]
      options:
        speed: 300
        easing: [ 0.34, 1.61, 0.7, 1 ]

    @pickRecipientsCatcher = new App.clickCatcher
      holder: @el.offsetParent()
      callback: @hide_recipients
      zIndexScale: 6

  hide_recipients: =>
    @pickRecipientsCatcher.remove()
    @pickRecipientsCatcher = null

    @recipientPicker.removeClass('is-open')

    @recipientList.velocity
      properties:
        scale: [ 0, 1 ]
        opacity: [ 0, 1 ]
      options:
        speed: 300
        easing: [ 500, 20 ]
        complete: -> @recipientList.addClass('hide')

  change_type: (e) ->
    $(e.target).addClass('active').siblings('.active').removeClass('active')
    # store $(this).data('value')

  add_recipient: (e) ->
    e.stopPropagation()
    e.preventDefault()
    console.log "add recipient", e
    # store recipient

  toggleVisibility: ->
    item = @$('.article-add')
    if item.hasClass('is-public')
      item.removeClass('is-public')
      item.addClass('is-internal')
      @$('[name="internal"]').val('true')
    else
      item.addClass('is-public')
      item.removeClass('is-internal')
      @$('[name="internal"]').val('')

  showSelectableArticleType: =>
    @el.find('.pop-selector').removeClass('hide')

    @selectTypeCatcher = new App.clickCatcher
      holder:      @el.offsetParent()
      callback:    @hideSelectableArticleType
      zIndexScale: 6

  selectArticleType: (e) =>
    articleTypeToSet = $(e.target).closest('.pop-selectable').data('value')
    @setArticleType( articleTypeToSet )
    @hideSelectableArticleType()

    @selectTypeCatcher.remove()
    @selectTypeCatcher = null

  hideSelectableArticleType: =>
    @el.find('.pop-selector').addClass('hide')

  setArticleType: (type) ->
    typeIcon = @el.find('.pop-selected .icon')
    if @type
      typeIcon.removeClass @type
    @type = type
    @$('[name="type"]').val(type)
    typeIcon.addClass @type

    # show/hide attributes
    for articleType in @articleTypes
      if articleType.name is type
        @$('.form-group').addClass('hide')
        for name in articleType.attributes
          @$("[name=#{name}]").closest('.form-group').removeClass('hide')

    # check if signature need to be added
    body      = @$('[data-name="body"]').html() || ''
    signature = undefined
    if @ticket.group.signature_id
      signature = App.Signature.find( @ticket.group.signature_id )
    if signature && signature.body && @type is 'email'
      signatureFinished = App.Utils.text2html(
        App.Utils.replaceTags( signature.body, { user: App.Session.get(), ticket: @ticket } )
      )
      if App.Utils.signatureCheck( body, signatureFinished )
        if !App.Utils.lastLineEmpty(body)
          body = body + '<br>'
        body = body + "<div data-signature=\"true\" data-signature-id=\"#{signature.id}\">#{signatureFinished}</div>"
        @$('[data-name="body"]').html(body)

    # remove old signature
    else
      @$('[data-name="body"]').find("[data-signature=true]").remove()

  detect_empty_textarea: =>
    if !@textarea.text().trim()
      @add_textarea_catcher()
    else
      @remove_textarea_catcher()

  open_textarea: (event, withoutAnimation) =>
    console.log('ticketEdit', @ticketEdit.hasClass('is-open'))
    if !@ticketEdit.hasClass('is-open')
      duration = 300

      if withoutAnimation
        duration = 0

      @ticketEdit.addClass('is-open')

      @textarea.velocity
        properties:
          minHeight: "#{ @textareaHeight.open - 38 }px"
        options:
          duration: duration
          easing: 'easeOutQuad'
          complete: => @add_textarea_catcher()

      @textBubble.velocity
        properties:
          paddingBottom: 28
        options:
          duration: duration
          easing: 'easeOutQuad'

      # scroll to bottom
      @textarea.velocity "scroll",
        container: @textarea.scrollParent()
        offset: 99999
        duration: 300
        easing: 'easeOutQuad'
        queue: false

      @editControlItem.velocity "transition.slideRightIn",
         duration: 300
         stagger: 50
         drag: true

      # move attachment text to the left bottom (bottom happens automatically)
      @attachmentPlaceholder.velocity
        properties:
          translateX: -@attachmentInputHolder.position().left + "px"
        options:
          duration: duration
          easing: 'easeOutQuad'

      @attachmentHint.velocity
        properties:
          opacity: 0
        options:
          duration: duration

  add_textarea_catcher: =>
    if @ticketEdit.is(':visible')
      @textareaCatcher = new App.clickCatcher
        holder: @ticketEdit.offsetParent()
        callback: @close_textarea
        zIndexScale: 4

  remove_textarea_catcher: ->
    return if !@textareaCatcher
    @textareaCatcher.remove()
    @textareaCatcher = null

  close_textarea: =>
    @remove_textarea_catcher()
    if !@textarea.text().trim() && !@attachments.length && not @isIE10()

      @textarea.velocity
        properties:
          minHeight: "#{ @textareaHeight.closed }px"
        options:
          duration: 300
          easing: 'easeOutQuad'
          complete: => @ticketEdit.removeClass('is-open')

      @textBubble.velocity
        properties:
          paddingBottom: 10
        options:
          duration: 300
          easing: 'easeOutQuad'

      @attachmentPlaceholder.velocity
        properties:
          translateX: 0
        options:
          duration: 300
          easing: 'easeOutQuad'

      @attachmentHint.velocity
        properties:
          opacity: 1
        options:
          duration: 300

      @editControlItem.css('display', 'none')

  onDragenter: (event) =>
    # on the first event,
    # open textarea (it will only open if its closed)
    @open_textarea() if @dragEventCounter is 0

    @dragEventCounter++
    @ticketEdit.parent().addClass('is-dropTarget')

  onDragleave: (event) =>
    @dragEventCounter--

    @ticketEdit.parent().removeClass('is-dropTarget') if @dragEventCounter is 0

  renderAttachment: (file) =>
    @attachmentsHolder.append App.view('generic/attachment_item')
      fileName: file.filename
      fileSize: @humanFileSize( file.size )
      store_id: file.store_id
    @attachmentsHolder.on(
      'click'
      "[data-id=#{file.store_id}]", (e) =>
        @attachments = _.filter(
          @attachments,
          (item) ->
            return if item.id isnt file.store_id
            item
        )
        store_id = $(e.currentTarget).data('id')

        # delete attachment from storage
        App.Ajax.request(
          type:  'DELETE'
          url:   App.Config.get('api_path') + '/ticket_attachment_upload'
          data:  JSON.stringify( { store_id: store_id } ),
          processData: false
          success: (data, status, xhr) =>
        )

        # remove attachment from dom
        element = $(e.currentTarget).closest('.attachments')
        $(e.currentTarget).closest('.attachment').remove()
        # empty .attachment (remove spaces) to keep css working, thanks @mrflix :-o
        if element.find('.attachment').length == 0
          element.empty()
    )

class ArticleView extends App.Controller
  constructor: ->
    super

    for ticket_article_id in @ticket_article_ids
      el = $('<div></div>')
      new ArticleViewItem(
        ticket:            @ticket
        ticket_article_id: ticket_article_id
        el:                el
        ui:                @ui
      )
      @el.append( el )

class ArticleViewItem extends App.Controller
  events:
    'click .show_toogle':  'show_toogle'
    'click .textBubble':   'toggle_meta_with_delay'
    'click .textBubble a': 'stopPropagation'
    'click .js-unfold':    'unfold'

  constructor: ->
    super
    @render()

  render: ->

    # get articles
    @article = App.TicketArticle.fullLocal( @ticket_article_id )

    # prepare html body
    if @article.content_type is 'text/html'
      @article['html'] = @article.body
    else
      @article['html'] = App.Utils.textCleanup( @article.body )
      @article['html'] = App.Utils.text2html( @article.body )

    @html App.view('ticket_zoom/article_view')(
      ticket:     @ticket
      article:    @article
      isCustomer: @isRole('Customer')
    )

    new App.WidgetAvatar(
      el:      @$('.js-avatar')
      user_id: @article.created_by_id
      size:    40
    )

    new ArticleActions(
      el:      @$('.js-article-actions')
      ticket:  @ticket
      article: @article
    )

    # show frontend times
    @frontendTimeUpdate()

  show_toogle: (e) ->
    e.stopPropagation()
    e.preventDefault()
    #$(e.target).hide()
    if $(e.target).next('div')[0]
      if $(e.target).next('div').hasClass('hide')
        $(e.target).next('div').removeClass('hide')
        $(e.target).text( App.i18n.translateContent('Fold in') )
      else
        $(e.target).text( App.i18n.translateContent('See more') )
        $(e.target).next('div').addClass('hide')

  stopPropagation: (e) ->
    e.stopPropagation()

  toggle_meta_with_delay: (e) =>
    # allow double click select
    # by adding a delay to the toggle

    if @lastClick and +new Date - @lastClick < 150
      clearTimeout(@toggleMetaTimeout)
    else
      @toggleMetaTimeout = setTimeout(@toggle_meta, 150, e)
      @lastClick = +new Date

  toggle_meta: (e) =>
    e.preventDefault()

    animSpeed      = 300
    article        = $(e.target).closest('.ticket-article-item')
    metaTopClip    = article.find('.article-meta-clip.top')
    metaBottomClip = article.find('.article-meta-clip.bottom')
    metaTop        = article.find('.article-content-meta.top')
    metaBottom     = article.find('.article-content-meta.bottom')

    if @elementContainsSelection( article.get(0) )
      @stopPropagation(e)
      return false

    if !metaTop.hasClass('hide')
      article.removeClass('state--folde-out')

      # scroll back up
      article.velocity "scroll",
        container: article.scrollParent()
        offset: -article.offset().top - metaTop.outerHeight()
        duration: animSpeed
        easing: 'easeOutQuad'

      metaTop.velocity
        properties:
          translateY: 0
          opacity: [ 0, 1 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'
          complete: -> metaTop.addClass('hide')

      metaBottom.velocity
        properties:
          translateY: [ -metaBottom.outerHeight(), 0 ]
          opacity: [ 0, 1 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'
          complete: -> metaBottom.addClass('hide')

      metaTopClip.velocity({ height: 0 }, animSpeed, 'easeOutQuad')
      metaBottomClip.velocity({ height: 0 }, animSpeed, 'easeOutQuad')
    else
      article.addClass('state--folde-out')
      metaBottom.removeClass('hide')
      metaTop.removeClass('hide')

      # balance out the top meta height by scrolling down
      article.velocity("scroll",
        container: article.scrollParent()
        offset: -article.offset().top + metaTop.outerHeight()
        duration: animSpeed
        easing: 'easeOutQuad'
      )

      metaTop.velocity
        properties:
          translateY: [ 0, metaTop.outerHeight() ]
          opacity: [ 1, 0 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'

      metaBottom.velocity
        properties:
          translateY: [ 0, -metaBottom.outerHeight() ]
          opacity: [ 1, 0 ]
        options:
          speed: animSpeed
          easing: 'easeOutQuad'

      metaTopClip.velocity({ height: metaTop.outerHeight() }, animSpeed, 'easeOutQuad')
      metaBottomClip.velocity({ height: metaBottom.outerHeight() }, animSpeed, 'easeOutQuad')

  unfold: (e) ->
    e.preventDefault()
    e.stopPropagation()
    container         = $(e.currentTarget).parents('.textBubble-content')
    overflowContainer = container.find('.textBubble-overflowContainer')

    overflowContainer.velocity
      properties:
        opacity: 0
      options:
        duration: 300

    container.velocity
      properties:
        height: container.attr('data-height')
      options:
        duration: 300
        complete: -> overflowContainer.addClass('hide');

  isOrContains: (node, container) ->
    while node
      if node is container
        return true
      node = node.parentNode
    false

  elementContainsSelection: (el) ->
    sel = window.getSelection()
    if sel.rangeCount > 0 && sel.toString()
      for i in [0..sel.rangeCount-1]
        if !@isOrContains(sel.getRangeAt(i).commonAncestorContainer, el)
          return false
      return true
    false

class ArticleActions extends App.Controller
  events:
    'click [data-type=public]':   'public_internal'
    'click [data-type=internal]': 'public_internal'
    'click [data-type=reply]':    'reply'
    'click [data-type=replyAll]': 'replyAll'

  constructor: ->
    super
    @render()

  render: ->
    actions = @actionRow(@article)

    if actions
      @html App.view('ticket_zoom/article_view_actions')(
        article: @article
        actions: actions
      )
    else
      @html ''

  public_internal: (e) ->
    e.preventDefault()
    article_id = $(e.target).parents('[data-id]').data('id')

    # storage update
    article = App.TicketArticle.find(article_id)
    internal = true
    if article.internal == true
      internal = false
    article.updateAttributes(
      internal: internal
    )

    # runntime update
    if internal
      $(e.target).closest('.ticket-article-item').addClass('is-internal')
    else
      $(e.target).closest('.ticket-article-item').removeClass('is-internal')

    @render()

  actionRow: (article) ->
    if @isRole('Customer')
      return []

    actions = []
    if article.internal is true
      actions = [
        {
          name: 'set to public'
          type: 'public'
        }
      ]
    else
      actions = [
        {
          name: 'set to internal'
          type: 'internal'
        }
      ]
    #if @article.type.name is 'note'
    #     actions.push []
    if article.type.name is 'email' || article.type.name is 'phone' || article.type.name is 'web'
      actions.push {
        name: 'reply'
        type: 'reply'
        href: '#'
      }
      recipients = []
      if article.sender.name is 'Agent'
        if article.to
            localRecipients = emailAddresses.parseAddressList(article.to)
            if localRecipients
              recipients = recipients.concat localRecipients
      else
        if article.from
          localRecipients = emailAddresses.parseAddressList(article.from)
          if localRecipients
            recipients = recipients.concat localRecipients
      if article.cc
        localRecipients = emailAddresses.parseAddressList(article.cc)
        if localRecipients
          recipients = recipients.concat localRecipients
      if recipients.length > 1
        actions.push {
          name: 'reply all'
          type: 'replyAll'
          href: '#'
        }
    actions.push {
      name: 'split'
      type: 'split'
      href: '#ticket/create/' + article.ticket_id + '/' + article.id
    }
    actions

  replyAll: (e) =>
    @reply(e, true)

  reply: (e, all = false) =>
    e.preventDefault()

    # get reference article
    article_id = $(e.target).parents('[data-id]').data('id')
    article    = App.TicketArticle.fullLocal( article_id )
    type       = App.TicketArticleType.find( article.type_id )
    customer   = App.User.find( article.created_by_id )

    @el.closest('.article-add').ScrollTo()

    # empty form
    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    #@el.closest('[name="in_reply_to"]').val('')

    if article.message_id
      articleNew.in_reply_to = article.message_id

    if type.name is 'twitter status'

      # set to in body
      to = customer.accounts['twitter'].username || customer.accounts['twitter'].uid
      articleNew.body = '@' + to

    else if type.name is 'twitter direct-message'

      # show to
      to = customer.accounts['twitter'].username || customer.accounts['twitter'].uid
      articleNew.to = to

    else if type.name is 'email' || type.name is 'phone' || type.name is 'web'

      if article.sender.name is 'Agent'
        articleNew.to = article.to
      else
        articleNew.to = article.from

        # if sender is customer but in article.from is no email, try to get
        # customers email via customer user
        if articleNew.to && !articleNew.to.match(/@/)
          articleNew.to = article.created_by.email

      # filter for uniq recipients
      recipientAddresses = {}
      recipient = emailAddresses.parseAddressList(articleNew.to)
      if recipient && recipient[0]
        recipientAddresses[ recipient[0].address.toString().toLowerCase() ] = true
      if all
        addAddresses = (lineNew, addressLine) ->
          localAddresses = App.EmailAddress.all()
          recipients     = emailAddresses.parseAddressList(addressLine)
          if recipients
            for recipient in recipients
              if recipient.address

                # check if addess is not local
                localAddess = false
                for address in localAddresses
                  if recipient.address.toString().toLowerCase() == address.email.toString().toLowerCase()
                    localAddess = true
                if !localAddess

                  # filter for uniq recipients
                  if !recipientAddresses[ recipient.address.toString().toLowerCase() ]
                    recipientAddresses[ recipient.address.toString().toLowerCase() ] = true

                    # add recipient
                    if lineNew
                      lineNew = lineNew + ', '
                    lineNew = lineNew + recipient.address
          lineNew

        if article.from
          articleNew.cc = addAddresses(articleNew.cc, article.from)
        if article.to
          articleNew.cc = addAddresses(articleNew.cc, article.to)
        if article.cc
          articleNew.cc = addAddresses(articleNew.cc, article.cc)

    # get current body
    body = @el.closest('[data-name="body"]').html() || ''

    # check if quote need to be added
    selectedText = App.ClipBoard.getSelected()
    if selectedText

      # clean selection
      selectedText = App.Utils.textCleanup( selectedText )

      # convert to html
      selectedText = App.Utils.text2html( selectedText )
      if selectedText
        selectedText = "<div><br><br/></div><div><blockquote type=\"cite\">#{selectedText}</blockquote></div><div><br></div>"

        # add selected text to body
        body = selectedText + body

    articleNew.body = body

    App.Event.trigger('ui::ticket::setArticleType', { ticket: @ticket, type: type, article: articleNew } )

class TicketZoomRouter extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      ticket_id:  params.ticket_id
      article_id: params.article_id
      nav:        params.nav

    App.TaskManager.execute(
      key:        'Ticket-' + @ticket_id
      controller: 'TicketZoom'
      params:     clean_params
      show:       true
    )

App.Config.set( 'ticket/zoom/:ticket_id', TicketZoomRouter, 'Routes' )
App.Config.set( 'ticket/zoom/:ticket_id/nav/:nav', TicketZoomRouter, 'Routes' )
App.Config.set( 'ticket/zoom/:ticket_id/:article_id', TicketZoomRouter, 'Routes' )
