class App.OrganizationProfileObject extends App.ControllerObserver
  memberLimit: 10
  model: 'Organization'
  observe:
    member_ids: true
  observeNot:
    cid: true
    created_at: true
    created_by_id: true
    updated_at: true
    updated_by_id: true
    preferences: true
    source: true
    image_source: true

  events:
    'click .js-showMoreMembers': 'showMoreMembers'
    'focusout [contenteditable]': 'update'

  showMoreMembers: (e) ->
    @preventDefaultAndStopPropagation(e)
    @memberLimit = (parseInt(@memberLimit / 100) + 1) * 100
    @renderMembers()

  renderMembers: ->
    elLocal = @el
    @organization.members(0, @memberLimit, (users) ->
      members = []
      for user in users
        el = $('<div></div>')
        new App.OrganizationProfileMember(
          object_id: user.id
          el: el
        )
        members.push el
      elLocal.find('.js-userList').html(members)
    )

    if @organization.member_ids.length <= @memberLimit
      @el.find('.js-showMoreMembers').parent().addClass('hidden')
    else
      @el.find('.js-showMoreMembers').parent().removeClass('hidden')

  render: (organization) =>
    if organization
      @organization = organization

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)

    # get display data
    organizationData = []
    for attributeName, attributeConfig of App.Organization.attributesGet('view')

      # check if value for _id exists
      name    = attributeName
      nameNew = name.substr(0, name.length - 3)
      if nameNew of @organization
        name = nameNew

      # add to show if value exists
      if (@organization[name] || attributeConfig.tag is 'richtext') && attributeConfig.shown

        # do not show firstname and lastname / already show via diplayName()
        if name isnt 'name'
          organizationData.push attributeConfig

    elLocal = $(App.view('organization_profile/object')(
      organization:     @organization
      organizationData: organizationData
    ))

    @html elLocal

    @renderMembers()

    @$('[contenteditable]').ce({
      mode:      'textonly'
      multiline: true
      maxlength: 250
    })

  update: (e) =>
    name  = $(e.target).attr('data-name')
    value = $(e.target).html()
    org   = App.Organization.find(@object_id)
    if org[name] isnt value
      @lastAttributes[name] = value
      data = {}
      data[name] = value
      org.updateAttributes(data)
      @log 'debug', 'update', name, value, org
