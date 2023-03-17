class App.KnowledgeBaseContentCanBePublishedForm extends App.ControllerForm
  elements:
    '.js-datepicker':    'datePicker'
    '[name=visibility]': 'visibilityRadios'
    '[value=now]':       'timingNow'
    '[value=scheduled]': 'timingScheduled'

  constructor: (params) ->
    @prepare(params)
    super
    @postRendering()
    @visibilityRadios.trigger('change')

  prepare: (params) ->
    @handlers = [@timingHandler, @visibilityHandler, @scheduledHandler]

    @params =
      visibility: params.object.can_be_published_state()

  scheduledHandler: (params, attribute, attributes, classname, form, ui) =>
    if attribute.name isnt 'scheduled'
      return

    if !params.scheduled
      return

    @timingScheduled.prop('checked', true)

  visibilityHandler: (params, attribute, attributes, classname, form, ui) =>
    if attribute.name isnt 'visibility'
      return

    @toggleDisabled(false)

    scheduledWidget = @form.find(".scheduled-widget[data-state=#{params.visibility}]")

    if scheduledWidget.length > 0 and !@form.find('.controls--datetime input[data-item=date]').val()
      date = scheduledWidget.data('date')
      @datePicker.datepicker('setDate', date)
    else
      @datePicker.datepicker('clearDates')
      @timingNow.prop('checked', true)

  timingHandler: (params, attribute, attributes, classname, form, ui) =>
    if attribute.name isnt 'timing'
      return

    if params.timing isnt 'now'
      return

    if !params.scheduled
      return

    @datePicker.datepicker('clearDates')

  postRendering: =>
    # simulate elements
    for key, value of @elements
      @[value] = @form.find(key)

    # move date picker to inside of timing radio
    @timingScheduled.parent().addClass('additional-radio-controls').append(@form.find('[data-name="scheduled"]'))
    @form.find('[data-attribute-name="scheduled"]').remove()
    @datePicker.datepicker('setStartDate', new Date())

    # add scheduled timer widgets
    now = new Date()

    for state in @states
      if @object["#{state}_at"] && new Date(@object["#{state}_at"]) > now
        label = @form.find("input[value=#{state}]").closest('label')
        timer = new App.KnowledgeBaseScheduledWidget(object: @object, state: state)
        label.after timer.el

  toggleDisabled: (state) ->
    selectedState  = @visibilityRadios.filter(':checked').val()
    timingDisabled = @params.visibility is selectedState
    isRollback     = @states.indexOf(@params.visibility) > @states.indexOf(selectedState)

    @form.find('[value=now], [type=submit]')
      .attr('disabled', state or timingDisabled)

    @form.find('[value=scheduled], .controls--datetime input')
      .attr('disabled', state or timingDisabled or isRollback)

    @visibilityRadios.attr('disabled', state)

  fullForm:                        true
  fullFormSubmitLabel:             __('Update')
  fullFormSubmitAdditionalClasses: 'btn--primary'
  states:                          [__('draft'), __('internal'), __('published'), __('archived')]

  model:
    configure_attributes: [
        name:    'visibility'
        display: __('Permissions')
        tag:     'radio'
        default: false
        options: [
            value: 'draft'
            name:  __('Draft')
            note:  __('Only visible to editors')
          ,
            value: 'internal'
            name:  __('Internal')
            note:  __('Visible to readers & editors')
          ,
            value: 'published'
            name:  __('Public')
            note:  __('Visible to everyone')
          ,
            value: 'archived'
            name:  __('Archived')
        ]
      ,
        name:    'timing'
        display: __('Timing')
        tag:     'radio'
        default: 'now'
        options: [
            value: 'now'
            name:  __('now')
          ,
            value: 'scheduled'
            name:  __('Schedule for')
        ]
      ,
        name:    'scheduled'
        display: __('Date')
        tag:     'datetime'
        class:   'form-control--small'
        null:    true
    ]
