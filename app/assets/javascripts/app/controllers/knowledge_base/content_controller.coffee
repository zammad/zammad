class App.KnowledgeBaseContentController extends App.Controller
  elements:
    '.js-form':            'form'
    '.js-discard':         'discardButton'
    '.js-submitContainer': 'submitContainer'

  events:
    'click .js-submit':        'submit'
    'click .js-discard':       'discardChanges'
    'submit .js-form':         'submit'
    'input .js-form':          'showDiscardButton'
    'click .js-submit-action': 'submit'

  constructor: ->
    super

    translation = @object.translation(@parentController.kb_locale().id)

    if translation and !translation.fullyLoaded()
      @html App.view('knowledge_base/content')(@)
      @startLoading()

      translation.loadFull (isSuccess) =>
        @stopLoading()

        if !isSuccess
          return

        @initialize()

      return

    @initialize()

  initialize: ->
    @render()

    @listenTo App.KnowledgeBase, 'kb_data_change_loaded', =>
      @objectRefreshed()
      true

    # update availability display whenever object is touched
    @listenTo @object, 'refresh', =>
      @renderAvailabilityWidgets()

  render: ->
    @html App.view('knowledge_base/content')(@)
    @renderAvailabilityWidgets()

    @formController = @buildFormController(@form)
    @startingParams = App.ControllerForm.params(@formController.el)

  buildFormController: (dom = undefined) ->
    new App.KnowledgeBaseFormController(@object, @parentController.kb_locale(), 'agent_edit', dom)

  remoteDidntChangeSinceStart: ->
    remoteParams = @buildFormController().rawParams()
    App.KnowledgeBaseFormController.compareParams(remoteParams, @startingParams)

  objectRefreshed: ->
    @renderAvailabilityWidgets()

    if @remoteDidntChangeSinceStart()
      @pendingRerender = false
      return

    if !@parentController.shown
      @pendingRerender = true
      return

    @rerenderIfConfirmed()

  rerenderIfConfirmed: ->
    text = App.i18n.translatePlain('Changes were made. Do you want to reload? You\'ll loose your changes')
    if confirm(text)
      @render()

  renderAvailabilityWidgets: ->
    if !@object.constructor.canBePublished?()
      return

    new App.WidgetButtonWithDropdown(
      el:              @submitContainer
      mainActionLabel: 'Update'
      actions:         @quickActions()
    )

    html = App.view('knowledge_base/content_can_be_published_header_suffix')(object: @object)
    @el.find('.js-published-header-suffix').replaceWith(html)

  submit: (e) ->
    @preventDefaultAndStopPropagation(e)

    if !@formController.validateAndShowErrors()
      return

    paramsForSaving = @formController.paramsForSaving()

    additional_action = $(e.currentTarget).data('id')

    if @remoteDidntChangeSinceStart()
      @parentController.coordinator.saveChanges(@object, paramsForSaving, @, additional_action)
      return

    new App.ControllerConfirm(
      head:    'Content was changed since loading'
      message: 'Your changes may override someone else\'s changes. Are you sure to save?'
      callback: =>
        @parentController.coordinator.saveChanges(@object, paramsForSaving, @)
    )

  missingTranslation: ->
    @object.translation(@parentController.kb_locale().id) is undefined && !@object.isNew()

  showDiscardButton: ->
    @delay =>
      noChanges = App.KnowledgeBaseFormController.compareParams(@formController.rawParams(), @startingParams)
      @discardButton.toggleClass('hide', noChanges)
    , 500, 'check_unsaved_changes'

  quickActions: ->
    prefix  = App.i18n.translatePlain('Update') + ' & '
    actions = @object.can_be_published_quick_actions()

    [
      {
        id:       'internal'
        name:     prefix + App.i18n.translatePlain('Internal')
        disabled: !_.includes(actions, 'internal')
      },{
        id:       'publish'
        name:     prefix + App.i18n.translatePlain('Publish')
        disabled: !_.includes(actions, 'publish')
      },{
        id:       'archive'
        name:     prefix + App.i18n.translatePlain('Archive')
        disabled: !_.includes(actions, 'archive')
      }
    ]

  discardChanges: ->
    @render()

  showAlert: (text) ->
    @formController?.showAlert(text)

  didSaveCallback: (data) ->
    @render()

    App.Event.trigger 'knowledge_base::sidebar::rerender'
    App.Event.trigger 'knowledge_base::navigation::rerender'

  # this method is called when user comes back to already instantiated view
  restoreVisibility: ->
    if !@pendingRerender
      return

    @pendingRerender = false

    # add delay to give it time to rerender before showing prompt
    App.Delay.set => @rerenderIfConfirmed()
