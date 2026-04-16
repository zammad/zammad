class TextTool extends App.ControllerAIFeatureBase
  @requiredPermission: 'admin.ai_assistance_text_tools'

  constructor: ->
    super

    callbackAnalyticsStatsAttribute = (value, object, attribute, attributes) ->
      if _.isEmpty(object.analytics_stats) or object.analytics_stats['total'] is 0
        return '-'

      App.view('ai/text_tool_feedback')(
        positive_feedback: object.analytics_stats['positive'] && object.analytics_stats['positive']['percent'] || 0
        negative_feedback: object.analytics_stats['negative'] && object.analytics_stats['negative']['percent'] || 0
      )

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
        leftButtons: [
          { name: __('Legal Information'), 'data-type': 'legal-information', class: 'btn--info' }
        ]
        buttons: [
          { name: __('New Writing Assistant Tool'), 'data-type': 'new', class: 'btn--success' }
        ]
        tableExtend: {
          callbackAttributes:
            analytics_stats: [ callbackAnalyticsStatsAttribute ]
          customActions: [
            {
              name: 'download-feedback-report'
              display: __('Download feedback report')
              icon: 'download'
              class: 'js-downloadFeedbackReport'
              callback: @downloadFeedbackReport
            }
            {
              name: 'reset-feedback-timestamp'
              display: __('Reset feedback')
              icon: 'reload'
              class: 'js-resetFeedbackTimestamp'
              callback: @resetFeedbackTimestamp
            }
          ]
        }
      container: @el.closest('.content')
      renderCallback: @renderCallback
    )

    @controllerBind('config_update', @configHasChanged)

  downloadFeedbackReport: (id) =>
    text_tool = App.AITextTool.find(id)

    @ajax(
      id:          'download_feedback_report'
      type:        'GET'
      url:         "#{@apiPath}/ai/analytics/download/with_usages?filters[triggered_by_type]=AI::TextTool&filters[triggered_by_id]=#{id}&filters[created_after]=#{text_tool.analytics_stats_reset_at}"
      processData: true
      dataType:    'binary'
      contentType: 'application/octet-stream'
      xhrFields:
        responseType: 'blob'
      success: (data, status, xhr) ->
        App.Utils.downloadFileFromBlob(data, xhr, { fallbackFilename: 'ai_analytics_with_usages.xlsx' })
      error: (xhr, status, error) =>
        @log 'error', error || status
        @notify(
          type: 'error'
          msg: __('The download could not be started. Please try again later.')
        )
    )

  resetFeedbackTimestamp: (id) =>
    @ajax(
      id:          'reset_feedback_timestamp'
      type:        'PUT'
      url:         "#{@apiPath}/ai_text_tools/#{id}/reset_analytics"
      processData: true
      success: (data) =>
        @genericController.render()
    )

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

App.Config.set('TextTool', { prio: 1200, name: __('Writing Assistant'), parent: '#ai', target: '#ai/text_tools', controller: TextTool, permission: ['admin.ai_assistance_text_tools'] }, 'NavBarAdmin')
