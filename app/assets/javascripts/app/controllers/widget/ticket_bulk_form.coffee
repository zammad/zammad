class App.TicketBulkForm extends App.Controller
  @extend App.TicketMassUpdatable

  className: 'bulkAction hide'

  events:
    'submit form':       'submit'
    'click .js-submit':  'submit'
    'click .js-confirm': 'confirm'
    'click .js-cancel':  'reset'

  @include App.ValidUsersForTicketSelectionMethods

  constructor: ->
    super

    return if !@permissionCheck('ticket.agent')

    @configure_attributes_ticket = []

    used_attributes = ['state_id', 'pending_time', 'priority_id', 'group_id', 'owner_id']
    attributesClean = App.Ticket.attributesGet('edit')
    for attributeName, attribute of attributesClean
      if _.contains(used_attributes, attributeName)
        localAttribute = clone(attribute)
        localAttribute.nulloption = true
        localAttribute.default = ''
        localAttribute.null = true
        @configure_attributes_ticket.push localAttribute

    # add field for ticket ids
    ticket_ids_attribute = { name: 'ticket_ids', display: false, tag: 'input', type: 'hidden', limit: 100, null: false }
    @configure_attributes_ticket.push ticket_ids_attribute

    time_attribute = _.findWhere(@configure_attributes_ticket, {'name': 'pending_time'})
    if time_attribute
      time_attribute.orientation = 'top'
      time_attribute.disableScroll = true

    @holder = @options.holder
    @visible = false

    load = (data) =>
      App.Collection.loadAssets(data.assets)
      @formMeta = data.form_meta
      @render()
    @bindId = App.TicketOverviewCollection.bind(load)

  release: =>
    App.TicketOverviewCollection.unbind(@bindId)

  render: ->
    @el.css('right', App.Utils.getScrollBarWidth())
    @el.addClass('no-sidebar') if @noSidebar

    @html(App.view('agent_ticket_view/bulk')())

    handlers = @Config.get('TicketZoomFormHandler')

    @controllerFormBulk = new App.ControllerForm(
      el: @$('#form-ticket-bulk')
      model:
        configure_attributes: @configure_attributes_ticket
        className:            'Ticket'
        labelClass:           'input-group-addon'
      screen:         'overview_bulk'
      handlersConfig: handlers
      params:         {}
      filter:         @formMeta.filter
      formMeta:       @formMeta
      noFieldset:     true
    )

    new App.ControllerForm(
      el: @$('#form-ticket-bulk-comment')
      model:
        configure_attributes: [{ name: 'body', display: __('Comment'), tag: 'textarea', rows: 4, null: true, upload: false, item_class: 'flex' }]
        className:            'Ticket'
        labelClass:           'input-group-addon'
      screen:     'overview_bulk_comment'
      noFieldset: true
    )

    @confirm_attributes = [
      { name: 'type_id',  display: __('Type'),       tag: 'select', multiple: false, null: true, relation: 'TicketArticleType', filter: @articleTypeFilter, default: '9', translate: true, class: 'medium' }
      { name: 'internal', display: __('Visibility'), tag: 'select', null: true, options: { true: 'internal', false: 'public' }, class: 'medium', item_class: '', default: false }
    ]

    new App.ControllerForm(
      el: @$('#form-ticket-bulk-typeVisibility')
      model:
        configure_attributes: @confirm_attributes
        className:            'Ticket'
        labelClass:           'input-group-addon'
      screen:     'overview_bulk_visibility'
      noFieldset: true
    )

  articleTypeFilter: (items) ->
    for item in items
      if item.name is 'note'
        return [item]
    items

  confirm: =>
    @$('.js-action-step').addClass('hide')
    @$('.js-confirm-step').removeClass('hide')

    @makeSpaceForTableRows()

    # need a delay because of the click event
    setTimeout ( => @$('.textarea.form-group textarea').trigger('focus') ), 0

  reset: =>
    @cancel()

    if @visible
      @makeSpaceForTableRows()

  cancel: =>
    @$('.js-action-step').removeClass('hide')
    @$('.js-confirm-step').addClass('hide')

  show: =>
    @el.removeClass('hide')
    @visible = true
    @makeSpaceForTableRows()

  hide: =>
    @el.addClass('hide')
    @visible = false
    @removeSpaceForTableRows()

  makeSpaceForTableRows: =>
    height = @el.height()
    scrollParent = @holder.scrollParent()
    isScrolledToBottom = scrollParent.prop('scrollHeight') is scrollParent.scrollTop() + scrollParent.outerHeight()

    @holder.css('margin-bottom', height)

    if isScrolledToBottom
      scrollParent.scrollTop scrollParent.prop('scrollHeight') - scrollParent.outerHeight()

  removeSpaceForTableRows: =>
    @holder.css('margin-bottom', 0)

  ticketMergeParams: (params) ->
    ticketUpdate = {}
    for item of params
      if params[item] != '' && params[item] != null
        ticketUpdate[item] = params[item]

    # in case if a group is selected, set also the selected owner (maybe nobody)
    if params.group_id != '' && params.group_id != null
      ticketUpdate.owner_id = params.owner_id
    ticketUpdate

  submit: (e) =>
    e.preventDefault()

    @bulkCount = @holder.find('.table').find('[name="bulk"]:checked').length

    if @bulkCount is 0
      App.Event.trigger('notify', {
        type: 'error'
        msg: App.i18n.translateContent('At least one object must be selected.')
      })
      return

    ticket_ids = []
    @holder.find('.table').find('[name="bulk"]:checked').each( (index, element) ->
      ticket_id = $(element).val()
      ticket_ids.push ticket_id
    )

    params = @formParam(e.target)

    for key, value of params
      if value == '' || value == null
        delete params[key]

    for ticket_id in ticket_ids
      ticket = App.Ticket.find(ticket_id)

      ticketUpdate = @ticketMergeParams(params)
      ticket.load(ticketUpdate)

      # if title is empty - ticket can't processed, set ?
      if _.isEmpty(ticket.title)
        ticket.title = '-'

      # validate ticket
      errors = ticket.validate(
        controllerForm: @controllerFormBulk
      )
      if errors
        @log 'error', 'update', errors
        errorString = ''
        for key, error of errors
          errorString += "#{key}: #{error}"

        @formValidate(
          form:   e.target
          errors: errors
          screen: 'edit'
        )

        App.Event.trigger('notify', {
          type: 'error'
          msg: App.i18n.translateContent('Bulk action stopped by error(s): %s!', errorString)
        })
        @cancel()
        return

    if params['body']
      article = new App.TicketArticle
      params.from      = @Session.get().displayName()
      params.form_id   = @form_id

      sender           = App.TicketArticleSender.findByAttribute('name', 'Agent')
      type             = App.TicketArticleType.find(params['type_id'])
      params.sender_id = sender.id

      if !params['internal']
        params['internal'] = false

      @log 'notice', 'update article', params, sender
      article.load(params)
      errors = article.validate()
      if errors
        @log 'error', 'update article', errors
        @formEnable(e)
        return


    data =
      ticket_ids: ticket_ids
      attributes: params
      article: article?.attributes()

    @ajax_mass_update(data, =>
      @holder.find('.table').find('[name="bulk"]:checked').prop('checked', false)
      @batchSuccess()
      @hide()
    )

  updateTicketIdsBulkForm: (e) ->
    items      = $(e.target).closest('table').find('input[name="bulk"]:checked')
    ticket_ids = _.map(items, (el) -> $(el).val() )
    @el.find('input[name=ticket_ids]').val(ticket_ids.join(',')).trigger('change')
