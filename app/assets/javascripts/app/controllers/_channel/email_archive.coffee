# Currently used only by cloud email channels, like: Google, Microsoft, etc.
class App.ChannelInboundEmailArchive extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  leftButtons: [
    {
      className: 'js-skip'
      text: __('Skip')
    }
  ]
  head: __('Archive Emails')
  small: true

  events:
    'click .js-skip': 'onSkip'

  content: ->
    content = $( App.view('channel/email_archive')(content_messages: @content_messages) )

    targetStateTypeIds = _.map(
      App.TicketStateType.search(filter:
        name: ['closed', 'open', 'new']
      ),
      (stateType) -> stateType.id
    )

    targetStateOptions = _.map(
      App.TicketState.search(filter:
        state_type_id: targetStateTypeIds
        active: true
      ),
      (targetState) ->
        value: targetState.id
        name: targetState.name
    )

    stateTypeClosed = App.TicketStateType.findByAttribute('name', 'closed')
    targetStateDefault = App.TicketState.findByAttribute('state_type_id', stateTypeClosed.id)

    configureAttributesAcknowledge = [
      { name: 'options::archive', display: __('Archive emails'), tag: 'switch', label_class: 'hidden', default: true },
      { name: 'options::archive_before', display: __('Archive cut-off time'), tag: 'datetime', null: false, help: __('Emails before the cut-off time are imported as archived tickets. Emails after the cut-off time are imported as regular tickets.') },
      { name: 'options::archive_state_id', display: __('Archive ticket target state'), tag: 'select', null: true, options: targetStateOptions, default: targetStateDefault.id },
    ]

    options =
      archive_before: @item?.options.inbound.options.archive_before
      archive_state_id: if @item?.options.inbound.options.archive_state_id then parseInt(@item.options.inbound.options.archive_state_id, 10)

    # Honour the archive flag, if channel is already configured.
    #   But not during the initial setup, i.e. via XOAUTH callback.
    options.archive = @item.options.inbound.options.archive or false if @item and !@set_active

    @form = new App.ControllerForm(
      el: content.find('.js-archiveSettings')
      model:
        configure_attributes: configureAttributesAcknowledge
        className: ''
      handlers: [
        App.FormHandlerChannelAccountArchiveMode.run
        App.FormHandlerChannelAccountArchiveBefore.run
      ]
      attributePrefix: 'options::'
      params:
        options: options
    )

    content

  onSubmit: (e) =>
    # get params
    params = @formParam(e.target)

    # validate form
    errors = @form.validate(params)

    # show errors in form
    if errors
      @log 'error', errors
      @formValidate(form: @form.form, errors: errors)
      return false

    # use jQuery's extend for deep extending
    $.extend(true, params, @inboundParams)

    @callback(params)
    @close()

  onSkip: (e) =>
    e.preventDefault()

    @callback(@inboundParams)
    @close()
