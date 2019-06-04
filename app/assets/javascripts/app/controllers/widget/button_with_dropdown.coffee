class App.WidgetButtonWithDropdown extends App.Controller
  elements:
    '.dropdown-menu-accessories': 'accessoriesContainer'

  events:
    'click li': 'clickedOption'

  constructor: ->
    super
    @render()

  mainActionLabel:            'Submit'
  mainActionIdentifier:       'js-submit'
  accessoryActionsIdentifier: 'js-submit-action'

  render: ->
    @el.addClass 'buttonDropdown dropdown dropup'

    @html App.view('widget/button_with_dropdown')(
      mainActionIdentifier:       @mainActionIdentifier
      accessoryActionsIdentifier: @accessoryActionsIdentifier
      mainActionLabel:            @mainActionLabel
      actions:                    @actions || []
    )

  clickedOption: (e) ->
    if e.currentTarget.hasAttribute('disabled')
      @preventDefaultAndStopPropagation(e)
      return

    @accessoriesContainer.blur()
