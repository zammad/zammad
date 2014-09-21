class Index extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/index')()

App.Config.set( 'layout_ref', Index, 'Routes' )


class Content extends App.ControllerContent
  events:
    'hide.bs.dropdown .js-recipientDropdown': 'hideOrganisationMembers'
    'click .js-organisation': 'showOrganisationMembers'
    'click .js-back':         'hideOrganisationMembers'

  constructor: ->
    super
    @render()

    for avatar in @$('.user.avatar')
      avatar = $(avatar)
      size = if avatar.hasClass('big') then 50 else 40
      @createUniqueAvatar avatar, size, avatar.data('firstname'), avatar.data('lastname'), avatar.data('userid')

  createUniqueAvatar: (holder, size, firstname, lastname, id) ->
    width = 300
    height = 226

    holder.addClass 'unique'

    rng = new Math.seedrandom(id);
    x = rng() * (width - size)
    y = rng() * (height - size)
    holder.css('background-position', "-#{ x }px -#{ y }px")

    holder.text(firstname[0] + lastname[0])

  render: ->
    @html App.view('layout_ref/content')()

  showOrganisationMembers: (e) =>
    e.stopPropagation()

    listEntry = $(e.currentTarget)
    organisationId = listEntry.data('organisation-id')

    @recipientList = @$('.recipientList')
    @organisationList = @$("##{ organisationId }")

    # move organisation-list to the right and slide it in

    $.Velocity.hook(@organisationList, 'translateX', '100%')
    @organisationList.removeClass('hide')

    @organisationList.velocity
      properties:
        translateX: 0
      options:
        speed: 300

    # fade out list

    @recipientList.velocity
      properties:
        translateX: '-100%'
      options:
        speed: 300
        complete: => @recipientList.height(@organisationList.height())

  hideOrganisationMembers: (e) =>
    e && e.stopPropagation()

    return if !@organisationList

    # fade list back in

    @recipientList.velocity
      properties:
        translateX: 0
      options:
        speed: 300

    # reset list height

    @recipientList.height('')

    # slide out organisation-list and hide it
    @organisationList.velocity
      properties:
        translateX: '100%'
      options:
        speed: 300
        complete: => @organisationList.addClass('hide')

App.Config.set( 'layout_ref/content', Content, 'Routes' )


class ContentSidebarRight extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/content_sidebar_right')()

App.Config.set( 'layout_ref/content_sidebar_right', ContentSidebarRight, 'Routes' )


class ContentSidebarRightSidebarOptional extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/content_sidebar_right_sidebar_optional')()

App.Config.set( 'layout_ref/content_sidebar_right_sidebar_optional', ContentSidebarRightSidebarOptional, 'Routes' )


class ModalForm extends App.ControllerModal
  constructor: ->
    super
    @head  = '123 some title'
    @cancel = true
    @button = true

    @render()

  render: ->
    controller = new App.ControllerForm(
      model: App.User
      autofocus: true
    )
    @el = controller.form

    @show()

  onHide: =>
    window.history.back()

  onSubmit: (e) =>
    e.preventDefault()
    params = App.ControllerForm.params( $(e.target).closest('form') )
    console.log('params', params)

App.Config.set( 'layout_ref/modal_form', ModalForm, 'Routes' )


class ModalText extends App.ControllerModal
  constructor: ->
    super
    @head = '123 some title'

    @render()

  render: ->
    @html App.view('layout_ref/content')()

    @show()

  onHide: =>
    window.history.back()

App.Config.set( 'layout_ref/modal_text', ModalText, 'Routes' )



class ContentSidebarTabsRight extends App.ControllerContent
  elements:
    '.tabsSidebar'  : 'sidebar'

  constructor: ->
    super
    @render()

    changeCustomerTicket = ->
      alert('change customer ticket')

    editCustomerTicket = ->
      alert('edit customer ticket')

    changeCustomerCustomer = ->
      alert('change customer customer')

    editCustomerCustomer = ->
      alert('edit customer customer')


    items = [
        head: 'Ticket Settings'
        name: 'ticket'
        icon: 'message'
        callback: (el) ->
          el.html('some ticket')
        actions: [
            name:  'Change Customer'
            class: 'glyphicon glyphicon-transfer'
            callback: changeCustomerTicket
          ,
            name:  'Edit Customer'
            class: 'glyphicon glyphicon-edit'
            callback: editCustomerTicket
        ]
      ,
        head: 'Customer'
        name: 'customer'
        icon: 'person'
        callback: (el) ->
          el.html('some customer')
        actions: [
            name:  'Change Customer'
            class: 'glyphicon glyphicon-transfer'
            callback: changeCustomerCustomer
          ,
            name:  'Edit Customer'
            class: 'glyphicon glyphicon-edit'
            callback: editCustomerCustomer
        ]
      ,
        head: 'Organization'
        name: 'organization'
        icon: 'group'
    ]

    new App.Sidebar(
      el:     @sidebar
      items:  items
    )

  render: ->
    @html App.view('layout_ref/content_sidebar_tabs_right')()

App.Config.set( 'layout_ref/content_sidebar_tabs_right', ContentSidebarTabsRight, 'Routes' )


class ContentSidebarLeft extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/content_sidebar_left')()

App.Config.set( 'layout_ref/content_sidebar_left', ContentSidebarLeft, 'Routes' )

App.Config.set( 'LayoutRef', { prio: 1700, parent: '#current_user', name: 'Layout Reference', target: '#layout_ref', role: [ 'Admin' ] }, 'NavBarRight' )
