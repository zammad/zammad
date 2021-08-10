class Organization extends App.SingleObjectPopoverProvider
  @klass = App.Organization
  @selectorCssClassPrefix = 'organization'
  @templateName = 'organization'
  @ignoredAttributes = ['name']

  displayTitleUsing: (object) ->
    object.name

  buildHtmlContent: (params) ->
    html = super

    params.object.members(0, 10, (users) ->
      members = []
      for user in users
        el = $('<div class="person"></div>')
        if user.active is false
          el.addClass('is-inactive')
        el.append(user.displayName())
        members.push el
      html.find('.js-userList').html(members)
    )

    html

App.PopoverProvider.registerProvider('Organization', Organization)
