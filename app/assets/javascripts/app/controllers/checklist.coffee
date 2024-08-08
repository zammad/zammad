class Checklist extends App.ControllerSubContent
  @requiredPermission: 'admin.checklist'
  header: __('Checklists')
  events:
    'change .js-checklistSetting input':  'toggleChecklistSetting'
    'click .js-description':              'description'
    'click .js-checklistNew':             'newChecklistTemplate'

  elements:
    '.js-checklistSetting input': 'checklistSetting'
    '#no-templates-hint':         'noTemplatesHint'
    '.js-description':            'descriptionButton'

  constructor: ->
    super
    App.ChecklistTemplate.fetchFull(
      =>
        App.Setting.fetchFull(
          @render,
          force: true,
        )
      force: true,
    )
    @templateSubscribeId = App.ChecklistTemplate.subscribe(@render)
    @settingSubscribeId  = App.Setting.subscribe(@render)

  release: =>
    super
    App.ChecklistTemplate.unsubscribe(@templateSubscribeId)
    App.Setting.unsubscribe(@settingSubscribeId)

  render: =>
    @html App.view('checklist/index')()

    templates = App.ChecklistTemplate.all()

    if !templates || templates.length is 0
      @noTemplatesHint.removeClass('hidden')
      @descriptionButton.addClass('hidden')
    else
      @noTemplatesHint.addClass('hidden')
      @descriptionButton.removeClass('hidden')

      new App.ControllerTable({
        el: @$('.js-checklistTemplatesTable')
        model: App.ChecklistTemplate
        objects: templates,
        bindRow:
          events:
            'click': @editChecklistTemplate
      })

  newChecklistTemplate: (e) =>
    e.preventDefault()

    new App.ControllerGenericNew(
      pageData:
        title: @header
        object: __('Checklist Template')
        objects: __('Checklist Templates')
      genericObject: 'ChecklistTemplate'
      container:     @el
      large:         true
      validateOnSubmit: @validateOnSubmit
    )

  editChecklistTemplate: (id, e) =>
    e.preventDefault()

    new App.ControllerGenericEdit(
      id: id
      pageData:
        title: @header
        object: __('Checklist Template')
        objects: __('Checklist Templates')
      genericObject: 'ChecklistTemplate'
      container:     @el
      large:         true
      validateOnSubmit: @validateOnSubmit
    )

  validateOnSubmit: (params) ->
    errors = {}
    if !params.items || params.items.length is 0
      errors['items'] = __('Please add at least one item to the checklist.')

    errors

  toggleChecklistSetting: (e) =>
    value = @checklistSetting.prop('checked')
    App.Setting.set('checklist', value)

  description: (e) =>
    new App.ControllerGenericDescription(
      description: App.ChecklistTemplate.description
      container:   @el
    )

App.Config.set('Checklists', { prio: 2340, name: __('Checklists'), parent: '#manage', target: '#manage/checklists', controller: Checklist, permission: ['admin.checklist'] }, 'NavBarAdmin')
