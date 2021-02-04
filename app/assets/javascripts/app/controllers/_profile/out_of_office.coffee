class ProfileOutOfOffice extends App.ControllerSubContent
  requiredPermission: 'user_preferences.out_of_office+ticket.agent'
  header: 'Out of Office'
  events:
    'submit form': 'submit'
    'click .js-disabled': 'disable'
    'click .js-enable': 'enable'

  constructor: ->
    super
    @render()

  render: =>
    user = @Session.get()
    if !@localData
      @localData =
        out_of_office: user.out_of_office
        out_of_office_start_at: user.out_of_office_start_at
        out_of_office_end_at: user.out_of_office_end_at
        out_of_office_replacement_id: user.out_of_office_replacement_id
        out_of_office_replacement_id_completion: user.preferences.out_of_office_replacement_id_completion
        out_of_office_text: user.preferences.out_of_office_text
    form = $(App.view('profile/out_of_office')(
      user: user
      localData: @localData
      placeholder: App.User.outOfOfficeTextPlaceholder()
    ))

    dateStart = new App.ControllerForm(
      model:
        configure_attributes:
          [
            name: 'out_of_office_start_at'
            display: ''
            tag: 'date'
            past: false
            future: true
            null: false
          ]
      noFieldset: true
      params: @localData
    )
    form.find('.js-startDate').html(dateStart.form)

    dateEnd = new App.ControllerForm(
      model:
        configure_attributes:
          [
            name: 'out_of_office_end_at'
            display: ''
            tag: 'date'
            past: false
            future: true
            null: false
          ]
      noFieldset: true
      params: @localData
    )
    form.find('.js-endDate').html(dateEnd.form)

    agentList = new App.ControllerForm(
      model:
        configure_attributes:
          [
            name: 'out_of_office_replacement_id'
            display: ''
            relation: 'User'
            tag: 'user_autocompletion'
            autocapitalize: false
            multiple: false
            limit: 30
            minLengt: 2
            placeholder: 'Enter Person or Organization/Company'
            null: false
            translate: false
            disableCreateObject: true
            value: @localData
          ]
      noFieldset: true
      params: @localData
    )
    form.find('.js-recipientDropdown').html(agentList.form)
    if @localData.out_of_office is true
      form.find('.js-disabled').removeClass('is-disabled')
      #form.find('.js-enable').addClass('is-disabled')
    else
      form.find('.js-disabled').addClass('is-disabled')
      #form.find('.js-enable').removeClass('is-disabled')
    @html(form)

  enable: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    params.out_of_office = true
    @store(e, params)

  disable: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    params.out_of_office = false
    @store(e, params)

  submit: (e, params) =>
    e.preventDefault()
    params = @formParam(e.target)
    @store(e, params)

  store: (e, params) =>
    @formDisable(e)
    for key, value of params
      @localData[key] = value
    App.Ajax.request(
      id:          'user_out_of_office'
      type:        'PUT'
      url:         "#{@apiPath}/users/out_of_office"
      data:        JSON.stringify(params)
      processData: true
      success:     @success
      error:       @error
    )

  success: (data) =>
    if data.message is 'ok'
      @render()
      @notify(
        type: 'success'
        msg:  App.i18n.translateContent('Successfully!')
        timeout: 1000
      )
    else
      if data.notice
        @notify
          type:      'error'
          msg:       App.i18n.translateContent(data.notice[0], data.notice[1])
          removeAll: true
      else
        @notify
          type:      'error'
          msg:       'Please contact your administrator.'
          removeAll: true
      @formEnable( @$('form') )

  error: (xhr, status, error) =>
    @formEnable( @$('form') )

    # do not close window if request is aborted
    return if status is 'abort'
    data = JSON.parse(xhr.responseText)

    # show error message
    if xhr.status is 403 || error is 'Not authorized'
      message     = '» ' + App.i18n.translateInline('Not authorized') + ' «'
    else if xhr.status is 404 || error is 'Not Found'
      message     = '» ' + App.i18n.translateInline('Not Found') + ' «'
    else if data.error
      message     = App.i18n.translateInline(data.error)
    else
      message     = '» ' + App.i18n.translateInline('Error') + ' «'
    @notify
      type:      'error'
      msg:       App.i18n.translateContent(message)
      removeAll: true

App.Config.set('OutOfOffice', { prio: 2800, name: 'Out of Office', parent: '#profile', target: '#profile/out_of_office', permission: ['user_preferences.out_of_office+ticket.agent'], controller: ProfileOutOfOffice }, 'NavBarProfile')
