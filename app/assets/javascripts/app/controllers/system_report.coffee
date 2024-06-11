class SystemReport extends App.ControllerSubContent
  @requiredPermission: 'admin.system_report'
  header: __('System Report')

  constructor: ->
    super
    @load()

  # fetch data, render view
  load: ->
    @startLoading()
    @ajax(
      id:    'system_report'
      type:  'GET'
      url:   "#{@apiPath}/system_report"
      success: (data) =>
        @stopLoading()
        @system_report = data.fetch
        @descriptions  = data.descriptions
        @render()
    )

  render: ->
    content = $(App.view('system_report')(
      system_report: @system_report
      descriptions: @descriptions
    ))

    configureAttributes = [
      { id: 'previewSystemReport', name: 'preview_system_report', tag: 'code_editor', null: true, disabled: true, lineNumbers: false, height: 620, value: JSON.stringify(@system_report, null, 2) },
    ]
    searchResultResponse = new App.ControllerForm(
      el: content.find('.js-previewSystemReport')
      model:
        configure_attributes: configureAttributes
      noFieldset: true
    )

    @html content

App.Config.set('SystemReport', { prio: 3800, name: __('System Report'), parent: '#system', target: '#system/system_report', controller: SystemReport, permission: ['admin.system_report'] }, 'NavBarAdmin' )
