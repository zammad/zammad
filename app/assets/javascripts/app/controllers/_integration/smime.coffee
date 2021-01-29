class Index extends App.ControllerIntegrationBase
  featureIntegration: 'smime_integration'
  featureName: 'S/MIME'
  featureConfig: 'smime_config'
  description: [
    ['S/MIME (Secure/Multipurpose Internet Mail Extensions) is a widely accepted method (or more precisely, a protocol) for sending digitally signed and encrypted messages.']
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
      facility: 'S/MIME'
    )

class Form extends App.Controller
  events:
    'click .js-addCertificate': 'addCertificate'
    'click .js-addPrivateKey': 'addPrivateKey'
    'click .js-updateGroup': 'updateGroup'

  constructor: ->
    super
    @render()

  currentConfig: ->
    App.Setting.get('smime_config')

  setConfig: (value) ->
    App.Setting.set('smime_config', value, {notify: true})

  render: =>
    @config = @currentConfig()

    @html App.view('integration/smime')(
      config: @config
    )
    @certList()
    @groupList()

  certList: =>
    new List(el: @$('.js-certList'))

  groupList: =>
    new Group(
      el: @$('.js-groupList')
      config: @config
    )

  addCertificate: =>
    new Certificate(
      callback: @certList
    )

  addPrivateKey: =>
    new PrivateKey(
      callback: @certList
    )

  updateGroup: (e) =>
    params = App.ControllerForm.params(e)
    @setConfig(params)

class Certificate extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'Add'
  autoFocusOnFirstInput: false
  head: 'Add Certificate'
  large: true

  content: ->

    # show start dialog
    content = $(App.view('integration/smime_certificate_add')(
      head: 'Add Certificate'
    ))
    content

  onSubmit: (e) =>
    params = new FormData($(e.currentTarget).closest('form').get(0))
    params.set('try', true)
    if _.isEmpty(params.get('data'))
      params.delete('data')
    @formDisable(e)

    @ajax(
      id:          'smime-certificate-add'
      type:        'POST'
      url:         "#{@apiPath}/integration/smime/certificate"
      processData: false
      contentType: false
      cache:       false
      data:        params
      success:     (data, status, xhr) =>
        @close()
        @callback()
      error: (data) =>
        @close()
        details = data.responseJSON || {}
        @notify
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to import!')
          timeout: 6000
    )

class PrivateKey extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'Add'
  autoFocusOnFirstInput: false
  head: 'Add Private Key'
  large: true

  content: ->

    # show start dialog
    content = $(App.view('integration/smime_private_key_add')(
      head: 'Add Private Key'
    ))
    content

  onSubmit: (e) =>
    params = new FormData($(e.currentTarget).closest('form').get(0))
    params.set('try', true)
    if _.isEmpty(params.get('data'))
      params.delete('data')
    @formDisable(e)

    @ajax(
      id:          'smime-private_key-add'
      type:        'POST'
      url:         "#{@apiPath}/integration/smime/private_key"
      processData: false
      contentType: false
      cache:       false
      data:        params
      success:     (data, status, xhr) =>
        @close()
        @callback()
      error: (data) =>
        @close()
        details = data.responseJSON || {}
        @notify
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to import!')
          timeout: 6000
    )


class List extends App.Controller
  events:
    'click .js-remove': 'remove'

  constructor: ->
    super
    @load()

  load: =>
    @ajax(
      id:    'smime-list'
      type:  'GET'
      url:   "#{@apiPath}/integration/smime/certificate"
      success: (data, status, xhr) =>
        @render(data)

      error: (data, status) =>

        # do not close window if request is aborted
        return if status is 'abort'

        details = data.responseJSON || {}
        @notify(
          type: 'error'
          msg:  App.i18n.translateContent(details.error_human || details.error || 'Unable to load list of certificates!')
        )

        # do something
    )

  render: (data) =>
    @html App.view('integration/smime_list')(
      certs: data
    )

  remove: (e) =>
    e.preventDefault()
    id = $(e.currentTarget).parents('tr').data('id')
    return if !id

    @ajax(
      id:    'smime-list'
      type:  'DELETE'
      url:   "#{@apiPath}/integration/smime/certificate"
      data:  JSON.stringify(id: id)
      success: (data, status, xhr) =>
        @load()

      error: (data, status) =>

        # do not close window if request is aborted
        return if status is 'abort'

        details = data.responseJSON || {}
        @notify(
          type: 'error'
          msg:  App.i18n.translateContent(details.error_human || details.error || 'Unable to save!')
        )
    )

class Group extends App.Controller
  constructor: ->
    super
    @render()

  render: (data) =>
    groups = App.Group.search(sortBy: 'name', filter: active: true)
    @html App.view('integration/smime_group')(
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
    App.Setting.get('smime_integration')

App.Config.set(
  'Integrationsmime'
  {
    name: 'S/MIME'
    target: '#system/integration/smime'
    description: 'S/MIME enables you to send digitally signed and encrypted messages.'
    controller: Index
    state: State
  }
  'NavBarIntegrations'
)
