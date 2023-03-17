class App.ManageKnowledgeBase extends App.ControllerTabs
  header: __('Knowledge Base')
  headerSwitchName: 'kb-activate'

  events:
    'hidden.bs.tab li': 'didHideTab'
    'show.bs.tab li':   'willShowTab'
    'change .js-header-switch input': 'didChangeHeaderSwitch'

  elements:
    '.js-header-switch input': 'headerSwitchInput'

  didHideTab: (e) ->
    selector = $(e.relatedTarget).attr('href')
    @$(selector).trigger('hidden.bs.tab')

  willShowTab: (e) ->
    selector = $(e.target).attr('href')
    @$(selector).trigger('show.bs.tab')

  tabs: []

  constructor: ->
    super

    @render()
    @fetchAndRender()

  fetchAndRender: =>
    @startLoading()

    @ajax(
      id:          'knowledge_bases_init_admin'
      type:        'GET'
      url:         "#{@apiPath}/knowledge_bases/manage/init"
      processData: true
      success:     (data, status, xhr) =>
        App.Collection.loadAssets(data)

        @knowledge_base_id = App.KnowledgeBase.first()?.id
        @stopLoading()
        @processLoaded()
      error:       (xhr) =>
        @knowledge_base_id = undefined
        @stopLoading()
    )

  clear: ->
    App.KnowledgeBase.find(@knowledge_base_id).remove(clear: true)
    @fetchAndRender()

  processLoaded: ->
    if @knowledge_base_id
      @renderLoaded()
    else
      @renderNonExistant()

  renderNonExistant: ->
    @headerSwitchInput.attr('disabled', true)

    @tabs =[
      {
        name:       __('Theme')
        target:     'style'
        controller: App.KnowledgeBaseNewController
        params:     { parentVC: @ }
      }
    ]

    @render()

  didChangeHeaderSwitch: ->
    @headerSwitchInput.prop('disabled', true)

    upcomingState = @headerSwitchInput.prop('checked')
    action = if upcomingState then 'activate' else 'deactivate'
    kb = App.KnowledgeBase.find(@knowledge_base_id)

    @ajax(
      id:          'knowledge_bases_init_admin'
      type:        'PATCH'
      url:         kb.manageUrl(action)
      processData: true
      success:     (data, status, xhr) =>
        App.Collection.loadAssets(data)
        @processLoaded()
        @headerSwitchInput.prop('disabled', false)
      error:       (xhr) =>
        @headerSwitchInput.prop('checked', !upcomingState)
        @headerSwitchInput.prop('disabled', false)
    )

  renderLoaded: ->
    @headerSwitchInput.attr('disabled', false)

    params = {
      knowledge_base_id: @knowledge_base_id
      parentVC:          @
    }

    @tabs = [
      {
        name:       __('Theme')
        target:     'style'
        controller: App.KnowledgeBaseForm
        params:     _.extend({}, params, { screen: 'style', split: true })
      },{
        name:       __('Languages')
        target:     'languages'
        controller: App.KnowledgeBaseForm
        params:     _.extend({}, params, { screen: 'languages' })
      },{
        name:       __('Public Menu')
        target:     'public_menu'
        controller: App.KnowledgeBasePublicMenuManager
        params:     _.extend({}, params, { screen: 'public_menu' })
      },{
        name:       __('Delete')
        target:     'delete'
        controller: App.KnowledgeBaseDelete
        params:     params
      }
    ]

    if !App.Config.get('system_online_service')
      @tabs.splice(-1, 0, {
        name:       __('Custom URL')
        target:     'custom_address'
        controller: App.KnowledgeBaseCustomAddressForm,
        params:     _.extend({}, params, { screen: 'custom_address' })
      })

    @render()

    @headerSwitchInput.prop('checked', App.KnowledgeBase.find(@knowledge_base_id).active)

App.Config.set('KnowledgeBase', { prio: 10000, name: __('Knowledge Base'), parent: '#manage', target: '#manage/knowledge_base', controller: App.ManageKnowledgeBase, permission: ['admin.knowledge_base'] }, 'NavBarAdmin')
