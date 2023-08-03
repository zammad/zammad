class User extends App.SingleObjectPopoverProvider
  @klass = App.User
  @selectorCssClassPrefix = 'user'
  @templateName = 'user'
  @ignoredAttributes = ['firstname', 'lastname', 'organization']
  @additionalHeadlineTemplateName: 'user_organization_headline'

  displayTitleUsing: (object) ->
    output = object.displayName()
    if object.isOutOfOffice()
      output += " (#{object.outOfOfficeText()})"
    output

App.PopoverProvider.registerProvider('User', User)
