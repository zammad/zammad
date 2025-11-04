class TextTool extends App.ControllerAIFeatureBase
  @requiredPermission: 'admin.ai_assistance_text_tools'

  constructor: ->
    super

    @genericController = new TextToolIndex(
      el: @el
      id: @id
      genericObject: 'AITextTool'
      defaultSortBy: 'name'
      searchBar: true
      searchQuery: @search_query
      pageData:
        home: 'text_tools'
        object: __('Writing Assistant Tool')
        objects: __('Writing Assistant Tools')
        searchPlaceholder: __('Search for writing assistant tools')
        pagerAjax: true
        pagerBaseUrl: '#ai/text_tools/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#ai/text_tools'
        buttons: [
          { name: __('New Writing Assistant Tool'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      renderCallback: @renderCallback
    )

    @controllerBind('config_update', @configHasChanged)

  configHasChanged: (config) =>
    return if config.name isnt 'ai_assistance_text_tools'

    @renderCallback()

  renderCallback: =>
    @renderAlert()

    if @hasUpdatedConfig
      @hasUpdatedConfig = false
      return

    @renderHeaderTitle()

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

  showAlert: ->
    App.Config.get('ai_assistance_text_tools') and !App.Config.get('ai_provider')

  pageHeaderTitle: =>
    @$('.page-header-title')

  renderHeaderTitle: =>
    return if not @pageHeaderTitle().length

    headerTitle = $('<h1 />').text(App.i18n.translatePlain('Writing Assistant'))

    toggleSwitch = App.UiElement.switch.render(
      class: 'js-toggle-switch-ai_text_tools',
      name: 'ai_assistance_text_tools'
      value: App.Config.get('ai_assistance_text_tools')
    )

    toggleSwitch.find('input[type="checkbox"]')
      .off('change.ai_assistance_text_tools')
      .on('change.ai_assistance_text_tools', (e) =>
        doneLocal = =>
          @hasUpdatedConfig = true

        App.Setting.set(e.target.name, e.target.checked, doneLocal: doneLocal, notify: true)
      )

    @pageHeaderTitle()
      .html(headerTitle)
      .prepend(toggleSwitch)

class TextToolIndex extends App.ControllerGenericIndex
  editControllerClass: -> EditTextTool
  newControllerClass: -> NewTextTool

TextToolModalMixin =
  headIcon: 'smart-assist-elaborate'
  headIconClass: 'ai-modal-head-icon'

  formParam: (form) ->
    params = App.ControllerForm.params(form)

    # Strip HTML tags from custom instructions.
    #   This is needed because the AI service expects plain text.
    params.instruction = App.Utils.html2text(params.instruction)

    params

  contentFormParams: ->
    params = $.extend(true, @item or {}, @fixedInstructions())

    # Add HTML tags to custom instructions.
    #   This is needed because the richtext editor needs to be able to show multiline text correctly.
    params.instruction = App.Utils.text2html(params.instruction)

    params

  fixedInstructions: ->
    fixed_instructions: App.Config.get('ai_assistance_text_tools_fixed_instructions')

class EditTextTool extends App.ControllerGenericEdit
  @include TextToolModalMixin

class NewTextTool extends App.ControllerGenericNew
  @include TextToolModalMixin

App.Config.set('TextTool', { prio: 1400, name: __('Writing Assistant'), parent: '#ai', target: '#ai/text_tools', controller: TextTool, permission: ['admin.ai_assistance_text_tools'] }, 'NavBarAdmin')
