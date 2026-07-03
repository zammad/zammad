# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.KnowledgeBaseVideoServersManager extends App.Controller
  @requiredPermission: 'admin.knowledge_base'
  events:
    'click .js-remove': 'remove'
    'click .js-new':    'new'
    'click .js-edit':   'edit'

  constructor: ->
    super
    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  release: =>
    App.Setting.unsubscribe(@subscribeId)

  servers: ->
    App.Setting.get('kb_self_hosted_video_servers') or []

  render: =>
    @html App.view('knowledge_base_video_servers/index')(
      servers: @servers()
    )

  new: (e) =>
    e.preventDefault()

    new Modal(
      head:      __('New Video Server')
      container: @el.closest('.content')
      callback:  (entry) =>
        @store(@servers().concat([entry]))
    )

  edit: (e) =>
    e.preventDefault()

    index = @indexFromEvent(e)

    new Modal(
      head:      __('Edit Video Server')
      container: @el.closest('.content')
      entry:     @servers()[index]
      callback:  (entry) =>
        servers = @servers().slice()
        servers[index] = entry
        @store(servers)
    )

  indexFromEvent: (e) ->
    $(e.currentTarget).closest('tr').data('index')

  remove: (e) =>
    e.preventDefault()

    index = @indexFromEvent(e)

    new App.ControllerConfirm(
      message: __('Are you sure? The embedded videos from this server will not be playable anymore.')
      buttonClass: 'btn--danger'
      callback: =>
        servers = @servers().slice()
        servers.splice(index, 1)

        @store(servers)
    )

  store: (servers) ->
    App.Setting.set('kb_self_hosted_video_servers', servers, notify: true)

class Modal extends App.ControllerModal
  buttonClose:  true
  buttonCancel: true
  buttonSubmit: true
  head:         __('Video Server')

  content: ->
    configure_attributes = [
      { name: 'name', display: __('Name'), tag: 'input',  null: false }
      { name: 'host', display: __('Host'), tag: 'input',  null: false, placeholder: 'video.example.com' }
    ]

    @form = new App.ControllerForm(
      model:  { configure_attributes: configure_attributes }
      params: @entry or {}
    )
    @form.form

  onSubmit: (e) =>
    params = @formParam(e.target)

    errors = @form.validate(params)
    if !_.isEmpty(errors)
      @formValidate(form: e.target, errors: errors)
      return

    @close()
    @callback(
      name:     params.name
      host:     @normalizeHost(params.host)
    )

  normalizeHost: (value) ->
    value
      .trim()
      .toLowerCase()
      .replace(/^https?:\/\//, '')
      .replace(/\/.*$/, '')

