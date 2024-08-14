class Index extends App.ControllerIntegrationBase
  featureIntegration: 'pgp_integration'
  featureName: __('PGP')
  featureConfig: 'pgp_config'
  description: [
    [__('Pretty Good Privacy (PGP) is an encryption program that can be used for signing, encrypting and decrypting messages and to increase the security of email communication.')]
  ]
  events:
    'change .js-switch input': 'switch'

  render: =>
    super
    new Form(
      el: @$('.js-form')
    )

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'PGP'
    )

    @checkStatus()

  checkStatus: =>
    @ajax(
      id:          'pgp-status'
      type:        'GET'
      url:         "#{@apiPath}/integration/pgp/status"
      success:     (data, status, xhr) =>
        return if _.isEmpty(data.error)

        $('<div>')
          .addClass('alert alert--danger')
          .text(data.error)
          .insertAfter(@$('.page-content > p'))

      error: (data) =>
        details      = data.responseJSON || {}
        errorMessage = details.error_human || details.error || __('The import failed.')
        @showAlert(App.i18n.translateContent(errorMessage))
        @formEnable(e)
    )

class Form extends App.Controller
  events:
    'click .js-addKey': 'addKey'
    'click .js-updateGroup': 'updateGroup'

  constructor: ->
    super
    @render()

  currentConfig: ->
    App.Setting.get('pgp_config')

  setConfig: (value) ->
    App.Setting.set('pgp_config', value, {notify: true})

  render: =>
    @config = @currentConfig()

    @html App.view('integration/pgp')(
      config: @config
    )
    @keysList()
    @groupList()

  keysList: =>
    @list = new List(el: @$('.js-keysList'))

  groupList: =>
    new Group(
      el: @$('.js-groupList')
      config: @config
    )

  addKey: =>
    new Key(
      callback: =>
        @list.load()
    )

  updateGroup: (e) =>
    params = App.ControllerForm.params(e)
    @setConfig(params)

class Key extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Add')
  autoFocusOnFirstInput: false
  head: __('Add Public or Private Key')
  large: true

  content: =>
    configure_attributes = [
      {
        name: 'file'
        display: __('Upload key')
        tag: 'input'
        input_type: 'file'
        null: true
      },
      {
        name: 'key'
        display: __('Paste key')
        tag: 'textarea'
        null: true
      },
      {
        name: 'passphrase'
        display: 'Passphrase'
        tag: 'input'
        input_type: 'password'
        null: true
      },
    ]

    if App.Config.get('pgp_recipient_alias_configuration')
      configure_attributes.push({
        name: 'domain_alias'
        display: __('Domain Alias')
        tag: 'input'
        null: true
        help: __('Enter a domain name that will be associated with this key, e.g. example.com.')
      })

    @controller = new App.ControllerForm(
      model:
        configure_attributes: configure_attributes
    )

    @addOrLineToForm(@controller.form)

    @controller.form

  addOrLineToForm: (elem) ->
    $('<div>')
      .addClass('form-field-group')
      .insertAfter(elem.find('.alert--danger'))
      .append(elem.find('[data-attribute-name=file],[data-attribute-name=key]'))

    $('<div>')
      .addClass('or-divider')
      .append($('<span>').text(App.i18n.translateContent(__('or'))))
      .insertAfter(elem.find('[data-attribute-name=file]'))

  onSubmit: (e) =>
    params = new FormData($(e.currentTarget).closest('form').get(0))
    @formDisable(e)

    @ajax(
      id:          'pgp-certificate-add'
      type:        'POST'
      url:         "#{@apiPath}/integration/pgp/key"
      processData: false
      contentType: false
      cache:       false
      data:        params
      success:     (data, status, xhr) =>
        @close()
        @callback()
      error: (data) =>
        details      = data.responseJSON || {}
        errorMessage = details.error_human || details.error || __('The import failed.')
        @showAlert(App.i18n.translateContent(errorMessage))
        @formEnable(e)
    )

class List extends App.Controller
  events:
    'click .js-remove': 'remove'

  constructor: ->
    super
    @load()

  load: =>
    @ajax(
      id:    'pgp-list'
      type:  'GET'
      url:   "#{@apiPath}/integration/pgp/key"
      success: (data, status, xhr) =>
        @render(data)

      error: (data, status) =>
        return if status is 'abort'

        details       = data.responseJSON || {}
        error_message = details.error_human || details.error || __('Loading failed.')

        @notify(
          type: 'error'
          msg:  error_message
        )
    )

  render: (data) =>
    @html App.view('integration/pgp_list')(
      keys: @formatData(data)
    )

  formatData: (data) ->
    _.map(data, (key) ->
      key.keygrip = _.reduce(key.fingerprint.match(/.{1,4}/g), (acc, val, idx) ->
        prefix = ''

        if idx > 0
          if idx == 5
            prefix = '&nbsp;&nbsp;'
          else
            prefix = ' '

        acc += prefix + val

      , '')

      if key.expires_at
        if Date.parse(key.expires_at) < Date.now()
          key.expires_at_css_class = 'label-danger'
        else if Date.parse(key.expires_at) < Date.now() + 7 * 24 * 60 * 60 * 1000 # one week before
          key.expires_at_css_class = 'label-warning'

      key
    )

  remove: (e) =>
    e.preventDefault()

    id = $(e.currentTarget).parents('tr').data('id')
    return if !id

    new App.ControllerConfirm(
      message:     __('Are you sure?')
      buttonClass: 'btn--danger'
      callback: =>
        @ajax(
          id:   'key_delete'
          type: 'DELETE'
          url:   "#{@apiPath}/integration/pgp/key/#{id}"
          success: (data, status, xhr) =>
            @load()

          error: (data, status) =>

            # do not close window if request is aborted
            return if status is 'abort'

            details = data.responseJSON || {}
            @notify(
              type: 'error'
              msg:  details.error_human || details.error || __('Server operation failed.')
            )
        )
      container: @el.closest('.content')
    )

class Group extends App.Controller
  constructor: ->
    super
    @render()

  render: (data) =>
    groups = App.Group.search(sortBy: 'name', filter: active: true)
    @html App.view('integration/pgp_group')(
      groups: groups
    )
    for group in groups
      for type, selector of { default_sign: 'js-signDefault', default_encryption: 'js-encryptionDefault' }
        selected = true
        if @config?.group_id && @config.group_id[type]
          selected = @config.group_id[type][group.id.toString()]
        selection = App.UiElement.boolean.render(
          name: "group_id::#{type}::#{group.id}"
          multiple: false
          null: false
          nulloption: false
          value: selected
          class: 'form-control--small'
        )
        @$("[data-id=#{group.id}] .#{selector}").html(selection)

class State
  @current: ->
    App.Setting.get('pgp_integration')

App.Config.set(
  'IntegrationPGP'
  {
    name: __('PGP')
    target: '#system/integration/pgp'
    description: __('Pretty Good Privacy (PGP) enables you to send digitally signed and encrypted messages.')
    controller: Index
    state: State
  }
  'NavBarIntegrations'
)
