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
        el = $('<li class="person"></li>')
        if user.active is false
          el.addClass('is-inactive')
        el.text(user.displayName())
        members.push el
      html.find('.js-organizationUserList').html(members)
    )

    html

App.PopoverProvider.registerProvider('Organization', Organization)
