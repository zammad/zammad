$ = jQuery.sub()

class Index extends App.Controller
  events:
    'click .submit':                          'update'
    'click [data-type=reply]':                'reply'
#    'click [data-type=reply-all]':            'replyall'
    'click [data-type=public]':               'public_internal'
    'click [data-type=internal]':             'public_internal'
    'change [name="ticket_article_type_id"]': 'form_update'
    'click .show_toogle':                     'show_toogle'
    'blur  .title_update':                    'title_update'

  constructor: (params) ->
    super
    @log 'zoom', params

    # check authentication
    return if !@authenticate()

    @navupdate '#'

    @form_id        = App.ControllerForm.formId()
    @edit_form      = undefined
    @ticket_id      = params.ticket_id
    @article_id     = params.article_id
    @signature      = undefined
    @signature_used = undefined

    @key = 'ticket::' + @ticket_id
    cache = App.Store.get( @key )
    if cache
      @load(cache)
    @fetch(@ticket_id)

  fetch: (ticket_id) ->

    # get data
    App.Com.ajax(
      id:    'ticket_zoom'
      type:  'GET'
      url:   '/api/ticket_full/' + ticket_id
      data:
        view: @view
      processData: true
      success: (data, status, xhr) =>
        @load(data)
        App.Store.write( @key, data )
    )

  load: (data) =>
    # reset old indexes
    @ticket = undefined
    @articles = undefined

    # get edit form attributes
    @edit_form = data.edit_form

    # get signature
    @signature = data.signature

    # load user collection
    App.Collection.load( type: 'User', data: data.users )

    # load ticket collection
    App.Collection.load( type: 'Ticket', data: [data.ticket] )

    # load article collections
    App.Collection.load( type: 'TicketArticle', data: data.articles )

    # render page
    @render()

  render: =>

    # get data
    if !@ticket
      @ticket = App.Collection.find( 'Ticket', @ticket_id )
    if !@articles
      @articles = []
      for article_id in @ticket.article_ids
        article = App.Collection.find( 'TicketArticle', article_id )
        @articles.push article

    # rework articles
    for article in @articles
      new Article( article: article )

    # set title
    @title 'Ticket Zoom ' + @ticket.number
    @configure_attributes_ticket = [
      { name: 'ticket_state_id',    display: 'State',    tag: 'select',   multiple: false, null: true, relation: 'TicketState', filter: @edit_form, translate: true, class: 'span2', item_class: 'pull-left' },
      { name: 'ticket_priority_id', display: 'Priority', tag: 'select',   multiple: false, null: true, relation: 'TicketPriority', filter: @edit_form, translate: true, class: 'span2', item_class: 'pull-left' },
      { name: 'group_id',           display: 'Group',    tag: 'select',   multiple: false, null: true, relation: 'Group', filter: @edit_form, class: 'span2', item_class: 'pull-left'  },
      { name: 'owner_id',           display: 'Owner',    tag: 'select',   multiple: false, null: true, relation: 'User', filter: @edit_form, nulloption: true, class: 'span2', item_class: 'pull-left' },
    ]
    if @isRole('Customer')
      @configure_attributes_ticket = [
        { name: 'ticket_state_id',    display: 'State',    tag: 'select',   multiple: false, null: true, relation: 'TicketState', filter: @edit_form, translate: true, class: 'span2', item_class: 'pull-left' },
        { name: 'ticket_priority_id', display: 'Priority', tag: 'select',   multiple: false, null: true, relation: 'TicketPriority', filter: @edit_form, translate: true, class: 'span2', item_class: 'pull-left' },
      ]

    @configure_attributes_article = [
      { name: 'ticket_article_type_id',   display: 'Type',        tag: 'select',   multiple: false, null: true, relation: 'TicketArticleType', filter: @edit_form, default: '9', translate: true, class: 'medium', item_class: '' },
      { name: 'to',                       display: 'To',          tag: 'input',    type: 'text', limit: 100, null: true, class: 'span7', item_class: 'hide' },
      { name: 'cc',                       display: 'Cc',          tag: 'input',    type: 'text', limit: 100, null: true, class: 'span7', item_class: 'hide' },
      { name: 'subject',                  display: 'Subject',     tag: 'input',    type: 'text', limit: 100, null: true, class: 'span7', item_class: 'hide' },
      { name: 'in_reply_to',              display: 'In Reply to', tag: 'input',    type: 'text', limit: 100, null: true, class: 'span7', item_class: 'hide' },
      { name: 'body',                     display: 'Text',        tag: 'textarea', rows: 6,  limit: 100, null: true, class: 'span7', item_class: '', upload: true  },
      { name: 'internal',                 display: 'Visability',  tag: 'select',   default: false,  null: true, options: { true: 'internal', false: 'public' }, class: 'medium', item_class: '' },
    ]
    if @isRole('Customer')
      @configure_attributes_article = [
        { name: 'to',                       display: 'To',          tag: 'input',    type: 'text', limit: 100, null: true, class: 'span7', item_class: 'hide' },
        { name: 'cc',                       display: 'Cc',          tag: 'input',    type: 'text', limit: 100, null: true, class: 'span7', item_class: 'hide' },
        { name: 'subject',                  display: 'Subject',     tag: 'input',    type: 'text', limit: 100, null: true, class: 'span7', item_class: 'hide' },
        { name: 'in_reply_to',              display: 'In Reply to', tag: 'input',    type: 'text', limit: 100, null: true, class: 'span7', item_class: 'hide' },
        { name: 'body',                     display: 'Text',        tag: 'textarea', rows: 6,  limit: 100, null: true, class: 'span7', item_class: '', upload: true  },
      ]

    @html App.view('agent_ticket_zoom')(
      ticket:   @ticket
      articles: @articles
      nav:      @nav
    )

    new App.ControllerForm(
      el:        @el.find('#form-ticket-update')
      form_id:   @form_id
      model:
        configure_attributes: @configure_attributes_ticket
        className:            'create'
      params:    @ticket
      form_data: @edit_form
    )

    new App.ControllerForm(
      el:        @el.find('#form-article-update')
      form_id:   @form_id
      model:
        configure_attributes: @configure_attributes_article
      form_data: @edit_form
    )

    @el.find('textarea').elastic()

    # enable user popups
    @userPopups()

    # show ticket action row
    @ticket_action_row()

    # show frontend times
    @frontendTimeUpdate()

    # scroll to article if given
    if @article_id && document.getElementById( 'article-' + @article_id )
      offset = document.getElementById( 'article-' + @article_id ).offsetTop
      offset = offset - 45
      scrollTo = ->
        @scrollTo( 0, offset )
      @delay( scrollTo, 100 )

  ticket_action_row: =>

    # start customer info controller
    if !@isRole('Customer')
      new App.UserInfo(
        el:      @el.find('#customer_info')
        user_id: @ticket.customer_id
        ticket:  @ticket
      )

    # start action controller
    if !@isRole('Customer')
      new TicketActionRow(
        el:      @el.find('#action_info')
        ticket:  @ticket
        zoom:    @
      )

    # start tag controller
    if !@isRole('Customer')
      new App.TagWidget(
        el:           @el.find('#tag_info')
        object_type:  'Ticket'
        object:        @ticket
      )

    # start link info controller
    if !@isRole('Customer')
      new App.LinkInfo(
        el:           @el.find('#link_info')
        object_type:  'Ticket'
        object:        @ticket
      )

    # show text module UI
    if !@isRole('Customer')
      new App.TextModuleUI(
        el:   @el.find('#text_module')
        data:
          ticket: @ticket
      )

  show_toogle: (e) ->
    e.preventDefault()
    $(e.target).hide()
    if $(e.target).next('div')[0]
      $(e.target).next('div').show()
    else
      $(e.target).parent().next('div').show()

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

    # runtime update
    for article in @articles
      if article_id is article.id
        article['internal'] = internal

    @render()

  form_update: (e) ->
    ticket_article_type_id = $(e.target).find('option:selected').val()
    article_type = App.TicketArticleType.find( ticket_article_type_id )
    @form_update_execute(article_type)

  form_update_execute: (article_type) =>
    if article_type.name is 'twitter status'

      # hide to
      @el.find('[name="to"]').parents('.control-group').addClass('hide')
      @el.find('[name="cc"]').parents('.control-group').addClass('hide')
      @el.find('[name="subject"]').parents('.control-group').addClass('hide')

    else if article_type.name is 'twitter direct-message'

      # show
      @el.find('[name="to"]').parents('.control-group').removeClass('hide')
      @el.find('[name="cc"]').parents('.control-group').addClass('hide')
      @el.find('[name="subject"]').parents('.control-group').addClass('hide')

    else if article_type.name is 'note'

      # hide to
      @el.find('[name="to"]').parents('.control-group').addClass('hide')
      @el.find('[name="cc"]').parents('.control-group').addClass('hide')
      @el.find('[name="subject"]').parents('.control-group').addClass('hide')

    else if article_type.name is 'email'

      # show
      @el.find('[name="to"]').parents('.control-group').removeClass('hide')
      @el.find('[name="cc"]').parents('.control-group').removeClass('hide')
#      @el.find('[name="subject"]').parents('.control-group').removeClass('hide')

      # add signature
      if !@signature_used && @signature && @signature.body
        @signature_used = true
        body = @el.find('[name="body"]').val() || ''
        body = body + "\n" + @signature.body
        @el.find('[name="body"]').val( body )

        # update textarea size
        @el.find('[name="body"]').trigger('change')

  reply: (e) =>
    e.preventDefault()
    article_id = $(e.target).parents('[data-id]').data('id')
    article = App.TicketArticle.find( article_id )
    article_type = App.TicketArticleType.find( article.ticket_article_type_id )
    customer = App.User.find( article.created_by_id )

    # update form
    @form_update_execute(article_type)

    # preselect article type
    @el.find('[name="ticket_article_type_id"]').find('option:selected').removeAttr('selected')
    @el.find('[name="ticket_article_type_id"]').find('[value="' + article_type.id + '"]').attr('selected',true)

    # empty form
    @el.find('[name="to"]').val('')
    @el.find('[name="cc"]').val('')
    @el.find('[name="subject"]').val('')
    @el.find('[name="in_reply_to"]').val('')

    if article.message_id
      @el.find('[name="in_reply_to"]').val(article.message_id)

    if article_type.name is 'twitter status'

      # set to in body
      to = customer.accounts['twitter'].username || customer.accounts['twitter'].uid
      @el.find('[name="body"]').val('@' + to)

    else if article_type.name is 'twitter direct-message'

      # show to
      to = customer.accounts['twitter'].username || customer.accounts['twitter'].uid
      @el.find('[name="to"]').val(to)

    else if article_type.name is 'email'
      @el.find('[name="to"]').val(article.from)
#    @log 'reply ', article, @el.find('[name="to"]')

    # add quoted text if needed
    selectedText = App.ClipBoard.getSelected()
    if selectedText
      body = @el.find('[name="body"]').val() || ''
      selectedText = selectedText.replace /^(.*)$/mg, (match) =>
        '> ' + match  
      body = selectedText + "\n" + body
      @el.find('[name="body"]').val(body)

      # update textarea size
      @el.find('[name="body"]').trigger('change')

  title_update: (e) =>
    $this = $(e.target)
    title = $this.html()
    title = ('' + title)
      .replace(/<.+?>/g, '')
    title = ('' + title)
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
    if title is '-'
      title = ''
    @ticket.title = title
    @ticket.load( title: title )
    @ticket.save()

  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    @log 'TicketZoom', 'notice', 'update', params, @ticket
    article_type = App.TicketArticleType.find( params['ticket_article_type_id'] )

    # update ticket
    ticket_update = {}
    for item in @configure_attributes_ticket
      ticket_update[item.name] = params[item.name]

    # check owner assignment
    if !@isRole('Customer')
      if !ticket_update['owner_id']
        ticket_update['owner_id'] = 1

    # check if title exists
    if !ticket_update['title'] && !@ticket.title
      alert( App.i18n.translateContent('Title needed') )
      return

    if article_type.name is 'email'

      # check if recipient exists
      if !params['to'] && !params['cc']
        alert( App.i18n.translateContent('Need recipient in "To" or "Cc".') )
        return

      # check if message exists
      if !params['body']
        alert( App.i18n.translateContent('Text needed') )
        return


    # check attachment
    if params['body']
      attachmentTranslated = App.i18n.translateContent('Attachment')
      attachmentTranslatedRegExp = new RegExp( attachmentTranslated, 'i' )
      if params['body'].match(/attachment/i) || params['body'].match( attachmentTranslatedRegExp )
        return if !confirm( App.i18n.translateContent('You use attachment in text but no attachment is attached. Do you want to continue?') )

    @ticket.load( ticket_update )
    @log 'TicketZoom', 'notice', 'update ticket', ticket_update, @ticket

    # disable form
    @formDisable(e)

    errors = @ticket.validate()
    if errors
      @log 'TicketZoom', 'error', 'update', errors
      @formEnable(e)

    @ticket.save(
      success: (r) =>

        # create article
        if params['body']
          article = new App.TicketArticle
          params.from      = @Session.get( 'firstname' ) + ' ' + @Session.get( 'lastname' )
          params.ticket_id = @ticket.id
          params.form_id   = @form_id

          if !params['internal']
            params['internal'] = false

          # find sender_id
          if @isRole('Customer')
            sender = App.Collection.findByAttribute( 'TicketArticleSender', 'name', 'Customer' )
            type   = App.Collection.findByAttribute( 'TicketArticleType', 'name', 'web' )
            params['ticket_article_type_id'] = type.id
          else
            sender = App.Collection.findByAttribute( 'TicketArticleSender', 'name', 'Agent' )
          params.ticket_article_sender_id = sender.id
          @log 'TicketZoom', 'notice', 'update article', params, sender
          article.load(params)
          errors = article.validate()
          if errors
            @log 'TicketZoom', 'error', 'update article', errors
          article.save(
            success: (r) =>
              @fetch(@ticket.id)
            error: (r) =>
              @log 'TicketZoom', 'error', 'update article', r
          )
        else
          @fetch(@ticket.id)
    )

#    errors = article.validate()
#    @log 'error new', errors
#    @formValidate( form: e.target, errors: errors )
    return false

class Article extends App.Controller
  constructor: ->
    super

    # define actions
    @actionRow()

    # check attachments
    @attachments()

    # html rework
    @preview()

  preview: ->

    # build html body
    # cleanup body
#    @article['html'] = @article.body.trim()
    @article['html'] = $.trim( @article.body )
    @article['html'].replace( /\n\r/g, "\n" )
    @article['html'].replace( /\n\n\n/g, "\n\n" )

    # if body has more then x lines / else search for signature
    preview       = 10
    preview_mode  = false
    article_lines = @article['html'].split(/\n/)
    if article_lines.length > preview
      preview_mode = true
      if article_lines[preview] is ''
        article_lines.splice( preview, 0, '----SEEMORE----' )
      else
        article_lines.splice( preview + 1, 0, '----SEEMORE----' )
      @article['html'] = article_lines.join("\n")
    @article['html'] = window.linkify( @article['html'] )
    notify = '<a href="#" class="show_toogle">' + App.i18n.translateContent('See more') + '</a>'

    # preview mode
    if preview_mode
      @article_changed = false
      @article['html'] = @article['html'].replace /^\n{0,10}----SEEMORE----\n/m, (match) =>
        @article_changed = true
        notify + '<div class="hide">'
      if @article_changed
        @article['html'] = @article['html'] + '</div>'

    # hide signatures and so on
    else
      @article_changed = false
      @article['html'] = @article['html'].replace /^\n{0,10}(--|__)/m, (match) =>
        @article_changed = true
        notify + '<div class="hide">' + match
      if @article_changed
        @article['html'] = @article['html'] + '</div>'


  actionRow: ->
    if @isRole('Customer')
      @article.actions = []
      return

    actions = []
    if @article.internal is true
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
    if @article.article_type.name is 'note'
#        actions.push []
    else
      if @article.article_sender.name is 'Customer'
        actions.push {
          name: 'reply'
          type: 'reply'
          href: '#'
        }
#        actions.push {
#          name: 'reply all'
#          type: 'reply-all'
#          href: '#'
#        }
        actions.push {
          name: 'split'
          type: 'split'
          href: '#ticket_create/' + @article.ticket_id + '/' + @article.id
        }
    @article.actions = actions

  attachments: ->
    if @article.attachments
      for attachment in @article.attachments
        attachment.size = @humanFileSize(attachment.size)

class TicketActionRow extends App.Controller
  events:
    'click [data-type=history]':  'history_dialog'
    'click [data-type=merge]':    'merge_dialog'
    'click [data-type=customer]': 'customer_dialog'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('ticket_action')()

  history_dialog: (e) ->
    e.preventDefault()
    new App.TicketHistory( ticket_id: @ticket.id )

  merge_dialog: (e) ->
    e.preventDefault()
    new App.TicketMerge( ticket_id: @ticket.id )

  customer_dialog: (e) ->
    e.preventDefault()
    new App.TicketCustomer( ticket_id: @ticket.id, zoom: @zoom )

App.Config.set( 'ticket/zoom/:ticket_id', Index, 'Routes' )
App.Config.set( 'ticket/zoom/:ticket_id/nav/:nav', Index, 'Routes' )
App.Config.set( 'ticket/zoom/:ticket_id/:article_id', Index, 'Routes' )