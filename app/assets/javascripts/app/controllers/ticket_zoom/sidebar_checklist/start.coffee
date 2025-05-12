class App.SidebarChecklistStart extends App.Controller
  events:
    'click .js-add-empty':                    'onAddEmpty'
    'click .js-add-from-template':            'onAddFromTemplate'
    'change [name="checklist_template_id"]':  'onTemplateChange'

  constructor: ->
    super
    @subscribeId = App.ChecklistTemplate.subscribe(@render)
    @render()

  release: =>
    App.ChecklistTemplate.unsubscribe(@subscribeId)

  render: =>
    @configure_attributes = [
      { name: 'checklist_template_id', display: __('Select Template'), tag: 'select', multiple: false, null: true, nulloption: true, relation: 'ChecklistTemplate', default: '' },
    ]

    @html App.view('ticket_zoom/sidebar_checklist/start')(
      showManageLink: App.User.current()?.permission('admin.checklist')
      readOnly: @readOnly
      activeTemplateCount: App.ChecklistTemplate.search(filter: { active: true })?.length
    )

    @controller = new App.ControllerForm(
      el:        @el.find('#form-checklist-template')
      model:
        configure_attributes: @configure_attributes
      autofocus: false
    )

  onAddEmpty: (e) =>
    @ajax(
      id:   'checklist_ticket_add_empty'
      type: 'POST'
      url:  "#{@apiPath}/checklists"
      data: JSON.stringify({ ticket_id: @parentVC.ticket.id, create_first_item: true })
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @parentVC.renderWidget(true)
    )

  onAddFromTemplate: (e) =>
    @preventDefaultAndStopPropagation(e)

    params = @formParam(e.target)
    if !params.checklist_template_id
      @showTemplateFieldError()
      return
    else
      @clearErrors()

    @ajax(
      id:   'checklist_ticket_add_from_template'
      type: 'POST'
      url:  "#{@apiPath}/checklists"
      data: JSON.stringify({ ticket_id: @parentVC.ticket.id, template_id: params.checklist_template_id })
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @parentVC.renderWidget()
    )

  onTemplateChange: (e) =>
    @preventDefaultAndStopPropagation(e)

    params = @formParam(e.target)
    return if !params.checklist_template_id

    @clearErrors()

  showTemplateFieldError: =>
    templateEl = @el.find('[name="checklist_template_id"]').closest('.form-group')
    templateEl.addClass('has-error')
    templateEl.find('.help-inline').html(App.i18n.translatePlain('Please select a checklist template.'))

  clearErrors: =>
    @el.find('form').find('.has-error').removeClass('has-error')
    @el.find('form').find('.help-inline').html('')

  showLoader: =>
    @el.find('.checklistStart').hide()
    @el.find('.loading-container').show()
