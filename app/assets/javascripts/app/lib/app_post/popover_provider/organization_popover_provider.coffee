class Organization extends App.SingleObjectPopoverProvider
  @klass = App.Organization
  @selectorCssClassPrefix = 'organization'
  @templateName = 'organization'
  @ignoredAttributes = ['name']

  displayTitleUsing: (object) ->
    object.name

App.PopoverProvider.registerProvider('Organization', Organization)
