class Index extends App.ControllerContent
  requiredPermission: 'user_preferences.access_token'
  events:
    'click .js-delete': 'delete'
    'submit form.js-create': 'create'

  constructor: ->
    super
    @title 'Token Access', true

    @load()
    @interval(
      =>
        @load()
      62000
    )

  # fetch data, render view
  load: (force = false) =>
    @ajax(
      id:    'user_access_token'
      type:  'GET'
      url:   "#{@apiPath}/user_access_token"
      success: (data) =>
        tokens = data.tokens

        # verify is rerender is needed
        if !force && @lastestUpdated && tokens && tokens[0] && @lastestUpdated.updated_at is tokens[0].updated_at
          return
        @lastestUpdated = tokens[0]
        @tokens = data.tokens
        @permissions = data.permissions
        @render()
    )

  render: =>
    @html App.view('profile/token_access')(
      tokens: @tokens
      permissions: @permissions
    )

  create: (e) =>
    e.preventDefault()
    params = @formParam(e.target)

    # check if min one permission exists
    if _.isEmpty(params['permission'])
      alert('Min. one permission is needed!')
      return

    if !_.isArray(params['permission'])
      params['permission'] = [params['permission']]

    @ajax(
      id:          'user_access_token_create'
      type:        'POST'
      url:         "#{@apiPath}/user_access_token"
      data:        JSON.stringify(params)
      processData: true
      success:     @show
      error:       @error
    )

  show: (data) =>
    @load()
    ui = @
    new App.ControllerModal(
      head: 'Your New Personal Access Token'
      buttonSubmit: 'OK, I\'ve copied my token'
      content: ->
        App.view('profile/token_access_created')(
          name: data.name
        )
      post: ->
        @el.find('.js-select').on('click', ui.selectAll)
      onCancel: ->
        @close()
      onSubmit: ->
        @close()
    )

  delete: (e) =>
    e.preventDefault()
    return if !confirm(App.i18n.translateInline('Sure?'))
    id = $(e.target).closest('a').data('token-id')
    @ajax(
      id:          'user_access_token_delete'
      type:        'DELETE'
      url:         "#{@apiPath}/user_access_token/#{id}"
      processData: true
      success: =>
        @load(true)
      error: @error
    )

  error: (xhr, status, error) =>
    data = JSON.parse(xhr.responseText)
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent(data.message)
    )

App.Config.set('Token Access', { prio: 3200, name: 'Token Access', parent: '#profile', target: '#profile/token_access', controller: Index, permission: ['user_preferences.access_token']  }, 'NavBarProfile')
